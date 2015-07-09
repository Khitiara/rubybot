require 'bundler/gem_tasks'

require_relative 'lib/rubybot/util/configuration_creator'

require 'rubocop/rake_task'
RuboCop::RakeTask.new

require 'guard/rake_task'
Guard::RakeTask.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task default: :spec

namespace :rubybot do
  desc 'Runs the rubybot'
  task :run do
    system 'bundle exec rubybot'
  end

  desc 'Creates the config'
  task 'create_config' do
    Rubybot::Util::ConfigurationCreator.new.create
  end
end
