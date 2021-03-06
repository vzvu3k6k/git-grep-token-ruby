# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grep_ruby_token/version'

Gem::Specification.new do |spec|
  spec.name          = 'grep_ruby_token'
  spec.version       = GrepRubyToken::VERSION
  spec.authors       = %w[uu59 vzvu3k6k]
  spec.email         = ['k@uu59.org', 'vzvu3k6k@gmail.com']
  spec.description   = 'Syntax-aware grep for Ruby code'
  spec.summary       = 'Syntax-aware grep for Ruby code'
  spec.homepage      = ''

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'parser', '~>2.5'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'minitest', '~> 5.11'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop', '~> 0.55'
end
