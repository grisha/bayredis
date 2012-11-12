
require "redis"
require "digest/sha1"

module Bayredis

  class Classifier

    def initialize(name)
      @name = name
      @r = Redis.new
    end

    def reset
      categories = @r.zrange("#{@name}:categories", 0, -1)
      categories.each { |category| @r.del("#{@name}:category:#{category}") }
      @r.del("#{@name}:categories")
    end

    def train(category, words)
      @r.zadd("#{@name}:categories", words.size, category)
      @r.zadd("#{@name}:category:#{category}", words.map {|w| [1, w]}.flatten)
    end

    def score(category, words)
      # Note that this happends entirely in the Redis server thanks to sorted sets and Lua!

      sha = Digest::SHA1.hexdigest(words.join)

      # feed the doc into redis with scores of 0
      @r.zadd("#{@name}:tmp:#{sha}:doc", words.map {|w| [0, w]}.flatten) #TODO expire me

      # find matching words for this category and their scores
      @r.zinterstore("#{@name}:tmp:#{sha}:score", ["#{@name}:tmp:#{sha}:doc", "#{@name}:category:#{category}"])

      # also add the missing words - so that an assumed score could be assigned to them
      @r.zunionstore("#{@name}:tmp:#{sha}:score", ["#{@name}:tmp:#{sha}:score", "#{@name}:tmp:#{sha}:doc"])

      compute_score("#{@name}:tmp:#{sha}:score", category)
    end

    def compute_score(zset, category, assumed_prob=0.1)
      lua = 
        "local zset = redis.call('zrange', ARGV[1], 0, -1, 'withscores') " +
        "local cat_size = redis.call('zscore', '#{@name}:categories', ARGV[2]) " +
        "local score = 0 " +
        "for i,v in ipairs(zset) do " +
        "  if i % 2 == 0 then " +            # even-numbered elements are scores
        "    if tonumber(v) == 0 then " +
        "       v = tonumber(ARGV[3]) " +    # score of 0 means unknown word, use assumed prob
        "    end " +
        "    score = score + math.log(v/cat_size) " +
        "  end " +
        "end " +
        "return string.format('%f', score) " # convert to string lest redis does to int

      @sum_scores_sha ||= @r.script('load', lua)
      @r.evalsha(@sum_scores_sha, [], [zset, category, assumed_prob]).to_f
    end

  end

end
