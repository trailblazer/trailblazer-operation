lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trailblazer/operation/version'

Gem::Specification.new do |spec|
  spec.name          = "trailblazer-operation"
  spec.version       = Trailblazer::Version::Operation::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]
  spec.description   = %q(Trailblazer's operation object.)
  spec.summary       = %q(Trailblazer's operation object with railway flow and integrated error handling.)
  spec.homepage      = "http://trailblazer.to"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "trailblazer-activity-dsl-linear", ">= 0.4.0", "< 1.0.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "trailblazer-developer"

  spec.required_ruby_version = ">= 2.1.0"
end
