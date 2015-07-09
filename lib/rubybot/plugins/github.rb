require 'rubybot/plugins/http_server'
require 'rubybot/core/github_message_formatter'
require 'gitio'
require 'cinch/formatting'
require 'cinch/helpers'
require 'yajl'

module Rubybot
  module Plugins
    class Github
      extend HttpServer::Verbs
      include Cinch::Plugin

      def initialize(bot)
        super
        @repos = config[:repos]
      end

      KNOWN_EVENTS = [:pull_request, :review_comment, :push, :issues, :issue_comment, :create, :delete, :fork,
                      :commit_comment, :status]

      before do
        request.body.rewind
        read             = request.body.read
        @request_payload = Yajl::Parser.parse(read, symbolize_keys: true)
      end

      post '/gh-hook', agent: %r{GitHub-Hookshot/.*} do
        payload = @request_payload
        event   = request.env['HTTP_X_GITHUB_EVENT']
        respond_for event, payload if KNOWN_EVENTS.include? event.to_sym
        204
      end

      private

      def respond_for(event, payload)
        response = send 'respond_for_' + event, payload
        return if response.nil?

        channels(payload).each do |chan|
          [response].flatten.each { |row| chan.msg row }
        end
      end

      def respond_for_pull_request(payload)
        format 'pull_request',
               repo: payload[:repository][:name],
               user: payload[:sender][:login],
               number: payload[:number],
               title: payload[:pull_request][:title],
               url: payload[:pull_request][:html_url]
      end

      def respond_for_review_comment(payload)
        format 'review_comment',
               repo: payload[:repository][:name],
               user: payload[:comment][:user][:login],
               number: payload[:pull_request_number],
               url: payload[:comment][:html_url],
               body: payload[:comment][:body]
      end

      def respond_for_push(payload)
        format 'push',
               repo: payload[:repository][:name],
               user: payload[:sender][:login],
               ref: payload[:ref],
               commits: payload[:commits],
               url: payload[:compare]
      end

      def respond_for_issues(payload)
        return if /(un)?labeled/ =~ payload[:action]
        format 'issues',
               repo: payload[:repository][:name],
               user: payload[:sender][:login],
               number: payload[:issue][:number],
               action: payload[:action],
               title: payload[:issue][:title],
               url: payload[:issue][:html_url]
      end

      def respond_for_issue_comment(payload)
        format 'issues',
               repo: payload[:repository][:name],
               user: payload[:comment][:user][:login],
               number: payload[:issue][:number],
               action: payload[:action],
               title: payload[:issue][:title],
               url: payload[:comment][:html_url],
               body: payload[:comment][:body]
      end

      def respond_for_create(payload)
        format 'create',
               repo: payload[:repository][:name],
               user: payload[:sender][:login],
               type: payload[:ref_type],
               name: payload[:ref],
               url: payload[:repository][:html_url]
      end

      def respond_for_delete(payload)
        format 'delete',
               repo: payload[:repository][:name],
               user: payload[:sender][:login],
               type: payload[:ref_type],
               name: payload[:ref],
               url: payload[:repository][:html_url]
      end

      def respond_for_fork(payload)
        format 'fork',
               repo: payload[:repository][:name],
               user: payload[:forkee][:owner][:login],
               url: payload[:forkee][:html_url]
      end

      def respond_for_commit_comment(payload)
        format 'commit_comment',
               repo: payload[:repository][:name],
               user: payload[:comment][:user][:login],
               commit: payload[:comment][:commit_id],
               url: payload[:comment][:html_url],
               body: payload[:comment][:body]
      end

      def respond_for_status(payload)
        format 'status',
               repo: payload[:repository][:name],
               user: payload[:commit][:commit][:author][:name],
               description: payload[:description],
               state: payload[:state],
               commit: payload[:sha],
               url: payload[:target_url]
      end

      def format(event, hash)
        Rubybot::Core::GithubMessageFormatter.format event, hash
      end

      def channels(payload)
        repo_owner = payload[:repository][:owner][:login] || payload[:repository][:owner][:name]
        chans = []
        chans += @repos[payload[:full_name]] if @repos.key? payload[:full_name]
        chans += @repos["#{repo_owner}/"] if @repos.key? "#{repo_owner}/"
        chans.map { |it| bot.channel_list.find it }
      end
    end
  end
end
