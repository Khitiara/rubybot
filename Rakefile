require_relative 'lib/rubybot/util/template_processor'
require 'highline/import'

namespace :rubybot do
  desc 'Runs the rubybot'
  task :run do
    system 'bundle exec rubybot'
  end

  desc 'Creates the config'
  task 'create_config' do
    if File.exists? 'config.json'
      return unless agree('config.json already exists, do you want to overwrite it? ')
    end

    variables = {
      server: nil,
      channel: nil,
      nick: nil,
      realname: nil,
      username: nil,
      sasl_username: nil,
      sasl_password: nil,

      twitter_consumer_key: nil,
      twitter_consumer_secret: nil,
      twitter_access_key: nil,
      twitter_access_secret: nil,

      github_repo: nil
    }
    if agree('Do you want to get help setting up your config? ')
      say 'IRC Setup'
      $terminal.indent do
        variables[:server] = ask 'IRC Server: '
        variables[:channel] = ask 'Channel (you can add more later): '
        variables[:nick] = ask 'Bot nickname: '
        variables[:realname] = ask('Bot realname: ') { |q| q.default = variables[:nick] }
        variables[:username] = ask('Bot username: ') { |q| q.default = variables[:nick] }
        if agree('Set up SASL? ')
          variables[:sasl_username] = ask 'SASL username: '
          variables[:sasl_password] = ask('SASL password: ') { |q| q.echo = '*' }
        end
      end

      say 'Twitter Setup'
      $terminal.indent do
        if agree('Do you want to set up Twitter? ')
          variables[:twitter_consumer_key] = ask('Twitter consumer key: ')
          variables[:twitter_consumer_secret] = ask('Twitter consumer secret: ')
        end
      end

      say 'Github Setup'
      $terminal.indent do
        if agree('Do you want to set up Github? ')
          variables[:github_repo] = ask('Github Repository to post from (more can be added later): ')
        end
      end
    end

    Rubybot::Util::TemplateProcessor.process_file variables, 'config.json.template' => 'config.json'
  end
end
