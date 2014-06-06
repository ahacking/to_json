# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'to_json/version'
require 'date'

Gem::Specification.new do |spec|
  spec.name          = "to_json"
  spec.version       = ::ToJson::VERSION
  spec.authors       = ["Andrew Hacking"]
  spec.date          = Date.today.to_s
  spec.email         = ["ahacking@gmail.com"]
  spec.homepage      = "https://github.com/ahacking/to_json"
  spec.summary       = %q{A pragmatic DSL for fast JSON serialization}
  spec.description   = spec.summary
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'oj', '>= 2.9.4'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
