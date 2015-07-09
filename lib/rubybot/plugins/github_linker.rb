require 'gitio'
require 'faraday/http_cache'
require 'octokit'
require 'active_support'
require 'rubybot/core/command_info'
require 'rubybot/core/github_message_formatter'

module Rubybot
  module Plugins
    class GithubLinker
      include Cinch::Plugin

      def initialize(bot)
        super

        @channels = config[:repos]

        @stack = Faraday::RackBuilder.new do |builder|
          builder.use Faraday::HttpCache
          builder.use Octokit::Response::RaiseError
          builder.adapter Faraday.default_adapter
        end

        Octokit.middleware = @stack

        @last = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      end

      listen_to :connect, method: :connected
      set plugin_name: 'github_linker'

      def commands(channel)
        help_short = 'Shows a quick summary about the given issue.'
        help_long = "#{help_short}\nAvailable values for <repo>: #{aliases_for_channel(channel.name).join ', '}"
        [
          Rubybot::Core::CommandInfo.new('<repo>#<number>', help_short, help_long: help_long, prefix: false),
          Rubybot::Core::CommandInfo.new('<repo> issue <number>', help_short, help_long: help_long, prefix: false)
        ]
      end

      # noinspection RubyResolve
      def connected(_)
        config[:repos].each do |channel, _|
          aliases_for_channel(channel).each do |a|
            repo = repo_for_alias(channel, a)
            this = self
            bot.on :message, /(?:\s|^)#{a}#([0-9]{1,4})(?:\s|$)/i do |m, issue_num|
              this.send :handle_issue_request, channel, issue_num, m, repo
            end
            bot.on :message, /(?:\s|^)#{a == '' ? '' : "#{a} "}issue ([0-9]{1,4})(?:\s|$)/i do |m, issue_num|
              this.send :handle_issue_request, channel, issue_num, m, repo
            end
          end
        end
      end

      private

      def aliases_for_channel(channel)
        config[:repos][channel.to_sym].map do |repo, _aliazes|
          repo # aliazes | [repo.to_s, repo.to_s.split('/')[1]]
        end.flatten
      end

      def repo_for_alias(channel, aliaz)
        config[:repos][channel.to_sym].each do |repo, aliazes|
          if aliazes.include?(aliaz) || aliaz == repo || aliaz == repo.to_s.split('/')[1]
            return repo
          end
        end
      end

      def handle_issue_request(channel, issue_num, message, repo)
        return unless message.target.name == channel.to_s

        cache_key = "#{repo}##{issue_num}"
        # prevent answering with the same issue multiple times
        @last[channel][cache_key] = Time.now.advance(days: -1) if @last[channel][cache_key].is_a? Hash
        if @last[channel][cache_key] < Time.now.advance(minutes: -5)
          begin
            issue = Octokit.issue repo.to_s, issue_num
            message.reply Rubybot::Core::GithubMessageFormatter.format_issue repo: repo.to_s,
                                                                             number: issue.number,
                                                                             url: issue.html_url,
                                                                             user: issue.user.login,
                                                                             title: issue.title
          rescue Octokit::NotFound # rubocop:disable Lint/HandleExceptions
            # ignored
          end
        end
        @last[channel][cache_key] = Time.now
      end
    end
  end
end
