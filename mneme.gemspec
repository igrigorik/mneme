# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mneme/version"

Gem::Specification.new do |s|
  s.name        = "mneme"
  s.version     = Mneme::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["TODO: Write your name"]
  s.email       = ["TODO: Write your email address"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "mneme"

  s.add_dependency "goliath"
  s.add_dependency "redis"
  s.add_dependency "yajl-ruby"
  s.add_dependency "hiredis"
  s.add_dependency "bloomfilter-rb"

  s.add_development_dependency "rspec"
  s.add_development_dependency "em-http-request", ">= 1.0.0.beta.3"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
