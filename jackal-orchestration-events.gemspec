$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'jackal-orchestration-events/version'
Gem::Specification.new do |s|
  s.name = 'jackal-orchestration-events'
  s.version = Jackal::OrchestrationEvents::VERSION.version
  s.summary = 'Message processing helper'
  s.author = 'Chris Roberts'
  s.email = 'code@chrisroberts.org'
  s.homepage = 'https://github.com/carnivore-rb/jackal-orchestration-events'
  s.description = 'Orchestration event helper'
  s.require_path = 'lib'
  s.license = 'Apache 2.0'
  s.add_dependency 'jackal'
  s.files = Dir['lib/**/*'] + %w(jackal-orchestration-events.gemspec README.md CHANGELOG.md CONTRIBUTING.md LICENSE)
end
