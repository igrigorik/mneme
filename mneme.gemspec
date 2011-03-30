# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "mneme"
  s.version     = "0.6.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ilya Grigorik"]
  s.email       = ["ilya@igvita.com"]
  s.homepage    = ""
  s.summary     = %q{abc}
  s.description = %q{Write a gem description}

  s.rubyforge_project = "mneme"

  s.add_dependency "goliath"
  s.add_dependency "hiredis"

  s.add_dependency "redis"
  s.add_dependency "yajl-ruby"
  s.add_dependency "bloomfilter-rb"

  s.add_development_dependency "rspec"
  s.add_development_dependency "em-http-request", ">= 1.0.0.beta.3"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
