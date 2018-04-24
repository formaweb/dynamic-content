# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dynamic_content/version'

Gem::Specification.new do |spec|
  spec.name          = "dynamic_content"
  spec.version       = DynamicContent::VERSION
  spec.authors       = ["Hugo Demiglio"]
  spec.email         = ["hugodemiglio@gmail.com"]

  spec.description   = %q{Simple way to manage dynamic fields with editable content on database for Rails and ActiveAdmin.}
  spec.summary       = %q{Editable content on dynamic fields.}
  spec.homepage      = 'http://github.com/formaweb/dynamic_content'
  spec.license       = 'MIT'

  spec.files         = `git ls-files lib`.split($/)
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'dragonfly', '~> 1.1'
  spec.add_dependency 'mime-types', '~> 3.0'
end
