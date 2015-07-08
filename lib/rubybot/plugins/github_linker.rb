require 'gitio'
require 'faraday/http_cache'
require 'octokit'
require 'active_support'

module Rubybot
  module Plugins
    class GithubLinker
      include Cinch::Plugin
      
      def initialize
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
        bot.bot_config[:github_linker].each do |channel, aliases|
          aliases.each do |repo, a2|
            a2 << repo
            a2 << repo.split('/')[1]
            a2.each do |a|
              bot.on :message, /(?:\s|^)#{a}#([0-9]{1,4})(?:\s|$)/i do |m, issue_num|
                if m.target == channel
                  puts JSON.pretty_generate(@last)
                  @last[channel]["#{repo}##{issue_num}"] = Time.now.advance(days: -1) if @last[channel]["#{repo}##{issue_num}"].is_a? Hash
                  if @last[channel]["#{repo}##{issue_num}"] < Time.now.advance(minutes: -5)
                    begin
                      issue = Octokit.issue repo, issue_num
                      m.reply "[#{Format(:pink, repo)} #{Format(:green, "##{issue.number}")}] - #{Gitio.shorten(issue.html_url)} #{issue.user.login}: \"#{issue.title}\""
                    rescue Octokit::NotFound
                      # ignored
                    end
                  end
                  @last[channel]["#{repo}##{issue_num}"] = Time.now
                end
              end
              bot.on :message, /(?:\s|^)#{a == '' ? '' : "#{a} "}issue ([0-9]{1,4})(?:\s|$)/i do |m, issue_num|
                if m.target == channel
                  puts JSON.pretty_generate(@last)
                  @last[channel]["#{repo}##{issue_num}"] = Time.now.advance(days: -1) if @last[channel]["#{repo}##{issue_num}"].is_a? Hash
                  if @last[channel]["#{repo}##{issue_num}"] < Time.now.advance(minutes: -5)
                    begin
                      issue = Octokit.issue repo, issue_num
                      m.reply "[#{Format(:pink, repo)} #{Format(:green, "##{issue.number}")}] - #{Gitio.shorten(issue.html_url)} #{issue.user.login}: \"#{issue.title}\""
                    rescue Octokit::NotFound
                      # ignored
                    end
                  end
                  @last[channel]["#{repo}##{issue_num}"] = Time.now
                end
              end
            end
          end
        end
      end
    end
  end
end
