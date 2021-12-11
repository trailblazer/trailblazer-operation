require "English"
lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "trailblazer/operation/version"

Gem::Specification.new do |spec|
  spec.name          = "trailblazer-operation"
  spec.version       = Trailblazer::Version::Operation::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]
  spec.description   = "Trailblazer's operation object."
  spec.summary       = "Trailblazer's operation object with railway flow and integrated error handling."
  spec.homepage      = "https://trailblazer.to/2.1/docs/operation.html"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "trailblazer-activity", ">= 0.12.2", "< 1.0.0"
  spec.add_dependency "trailblazer-activity-dsl-linear", ">= 0.4.1", "< 1.0.0"
  spec.add_dependency "trailblazer-developer", ">= 0.0.21", "< 1.0.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop"

  spec.required_ruby_version = ">= 2.1.0"
end
