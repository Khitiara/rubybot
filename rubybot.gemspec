lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rubybot/version'

Gem::Specification.new do |spec|
  spec.name          = 'rubybot'
  spec.version       = Rubybot::VERSION
  spec.authors       = %w(robotbrain 02JanDal)
  spec.email         = %w(robotbrain@robotbrain.info 02jandal@gmail.com)
  spec.description   = <<DESC
The ninth iteration of the ElrosBot project.

A modular IRC bot with many useful modules, based on Cinch.

The included modules include:

 * GitHub notifications (like notifico)
 * GitHub issue linker
 * Ping lists
 * Factoids (static help and information items)
 * Sed
 * Google
DESC
  spec.summary       = 'A modular IRC bot with many useful modules, based on Cinch.'
  spec.homepage      = 'https://github.com/robotbrain/rubybot'
  spec.license       = 'GPL'

  spec.files         = Dir['./**/*']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-nav'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-collection_matchers'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'cinch-test'
  spec.add_dependency 'highline'
  spec.add_dependency 'cinch', '~>2.1.0'
  spec.add_dependency 'rack', '~>1.1'
  spec.add_dependency 'timers', '~>4.0.1'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'revolver', '~> 1.1.1'
  spec.add_dependency 'yajl-ruby'

  # Plugin requirements
  spec.add_dependency 'git.io', '~> 0.0.3'
  spec.add_dependency 'googleajax'
  spec.add_dependency 'sanitize'
  spec.add_dependency 'octokit', '~> 3.8'
  spec.add_dependency 'faraday-http-cache', '~> 1.1'
  spec.add_dependency 'google-api-client'
  spec.add_dependency 'chronic_duration'
  spec.add_dependency 'iso8601'
  spec.add_dependency 'sinatra'
  spec.add_dependency 'thin'
  spec.add_dependency 'twitter'
end
