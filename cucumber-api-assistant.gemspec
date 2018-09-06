# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cucumber-api-assistant/version"

Gem::Specification.new do |s|
  s.name        = "cucumber-api-assistant"
  s.version     = CucumberApiAssistant::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Michael Keeling", "Michael Lipschultz", "Ryan Moore"]
  s.email       = ["mkeeling@neverletdown.net"]
  s.homepage    = ""
  s.summary     = %q{Cucumber step functions for API testing}
  s.description = %q{Cucumber step functions for API testing.}
  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 1.9.3'
  s.license     = 'MIT'

  s.add_dependency('cucumber', '~> 2.0')
  s.add_dependency('jsonpath', '~> 0.5')
  s.add_dependency('excon', '~> 0.51')
  s.add_dependency('certified', '~> 1.0')
  s.add_dependency('json-schema', '~> 2.5')
  s.add_dependency('rspec-expectations', '~> 3.5.0')
end
