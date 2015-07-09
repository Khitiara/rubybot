require 'highline'
require 'active_support/core_ext/module/delegation'
require 'rubybot/util/template_processor'

module Rubybot
  module Util
    class ConfigurationCreator
      def initialize
        @term = HighLine.new
      end

      delegate :agree, :say, :indent, :ask, to: :@term

      def create
        if File.exist? 'config.json'
          return unless agree('config.json already exists, do you want to overwrite it? ')
        end

        variables = { info: nil }
        if agree('Do you want to get help setting up your config? ')
          variables[:info] = ask 'Information to display with help command: '
          variables.merge!(query_irc).merge(query_twitter).merge(query_github).merge(query_youtube)
        end

        Rubybot::Util::TemplateProcessor.process_file variables, 'config.json.template' => 'config.json'
      end

      private

      def query_irc
        variables = { server: nil,
                      channel: nil,
                      nick: nil,
                      realname: nil,
                      username: nil,
                      sasl_username: nil,
                      sasl_password: nil }

        say 'IRC Setup'
        indent do
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

        variables
      end

      def query_twitter
        variables = {
          twitter_consumer_key: nil,
          twitter_consumer_secret: nil,
          twitter_access_token: nil,
          twitter_access_token_secret: nil
        }

        say 'Twitter Setup'
        indent do
          if agree('Do you want to set up Twitter? ')
            variables[:twitter_consumer_key] = ask('Twitter consumer key: ')
            variables[:twitter_consumer_secret] = ask('Twitter consumer secret: ')
            variables[:twitter_access_token] = ask('Twitter access token: ')
            variables[:twitter_access_token_secret] = ask('Twitter access token secret: ')
          end
        end

        variables
      end

      def query_github
        variables = {
          github_repo: nil
        }

        say 'Github Setup'
        indent do
          if agree('Do you want to set up Github? ')
            variables[:github_repo] = ask('Github Repository to post from (more can be added later): ')
          end
        end

        variables
      end

      def query_youtube
        variables = {
          youtube_key: nil
        }

        say 'Youtube Setup'
        indent do
          if agree('Do you want to set up Youtube? ')
            variables[:youtube_key] = ask('Youtube key: ')
          end
        end

        variables
      end
    end
  end
end
