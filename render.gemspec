# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'render/version'

Gem::Specification.new do |spec|
  spec.name          = "render"
  spec.version       = Render::VERSION
  spec.authors       = ["Steve Weber"]
  spec.email         = ["steve@copyright1984.com"]
  spec.description   = %q{Simple management of API calls.}
  spec.summary       = %q{With a JSON schema, Render will manage requests, dependent request and build meaningful, extensible sample data for testing.}
  spec.homepage      = "https://github.com/stevenweber/render"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency "uuid", "2.3.7"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "debugger"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"
end
