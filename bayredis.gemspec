# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bayredis/version'

Gem::Specification.new do |gem|
  gem.name          = "bayredis"
  gem.version       = Bayredis::VERSION
  gem.authors       = ["Grisha Trubetskoy"]
  gem.email         = ["grisha.trubetskoy@livingsocial.com"]
  s.summary         = %q{Completely Redis-side Bayesian classifier}
  s.description     = %q{This classifier uses Sorted Sets and Lua to compute a score completely on the Redis server}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  s.add_development_dependency "redis"
  s.add_runtime_dependency "redis"
end
