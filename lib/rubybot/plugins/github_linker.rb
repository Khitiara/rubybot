require 'gitio'
require 'faraday/http_cache'
require 'octokit'
require 'active_support'

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

      # noinspection RubyResolve
      def connected(_)
        config[:repos].each do |channel, aliases|
          aliases.each do |repo, a2|
            a2 << repo.to_s << repo.to_s.split('/')[1]
            a2.each do |a|
              bot.on :message, /(?:\s|^)#{a}#([0-9]{1,4})(?:\s|$)/i do |m, issue_num|
                handle_issue_request channel, issue_num, m, repo
              end
              bot.on :message, /(?:\s|^)#{a == '' ? '' : "#{a} "}issue ([0-9]{1,4})(?:\s|$)/i do |m, issue_num|
                handle_issue_request channel, issue_num, m, repo
              end
            end
          end
        end
      end

      private

      def handle_issue_request(channel, issue_num, message, repo)
        return unless message.target == channel

        cache_key = "#{repo}##{issue_num}"
        # prevent answering with the same issue multiple times
        @last[channel][cache_key] = Time.now.advance(days: -1) if @last[channel][cache_key].is_a? Hash
        if @last[channel][cache_key] < Time.now.advance(minutes: -5)
          begin
            issue = Octokit.issue repo, issue_num
            number = issue.number
            url = Gitio.shorten issue.html_url
            owner = issue.user.login
            title = issue.title
            message.reply "[#{Format(:pink, repo)} #{Format(:green, "##{number}")}] - #{url} #{owner}: \"#{title}\""
          rescue Octokit::NotFound # rubocop:disable Lint/HandleExceptions
            # ignored
          end
        end
        @last[channel][cache_key] = Time.now
      end
    end
  end
end
