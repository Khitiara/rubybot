require_relative '../http/http_server'
require 'gitio'
require 'cinch/formatting'
require 'cinch/helpers'

# noinspection RubyResolve
$channels = $config['github_repos']

class Github
  extend Cinch::HttpServer::Verbs
  include Cinch::Plugin

  before do
    request.body.rewind
    @request_payload = JSON.parse(request.body.read, {:symbolize_names => true})
  end

  post '/gh-hook', :agent => /GitHub-Hookshot\/.*/ do
    payload = @request_payload
    event = request.env['HTTP_X_GITHUB_EVENT']
    case event
      when 'pull_request'
        issue = payload[:number]
        action = payload[:action]
        repo = payload[:repository][:name]
        title = payload[:pull_request][:title]
        url = Gitio::shorten payload[:pull_request][:html_url]
        user = payload[:sender][:login]
        $channels[payload[:repository][:full_name]].map { |it|
          bot.channel_list.find_ensured(it) }.each { |chan| chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{user} #{action} pull request #{Cinch::Formatting.format(:green, "\##{issue}")}: \"#{title}\" - #{url}" }

      when 'pull_request_review_comment'
        url = Gitio::shorten payload[:comment][:html_url]
        issue = payload[:pull_request][:number]
        user = payload[:comment][:user][:login]
        repo = payload[:repository][:name]
        $channels[payload[:repository][:full_name]].map { |it|
          bot.channel_list.find_ensured(it) }.each { |chan| chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} reviewed pull request #{Cinch::Formatting.format(:green, "\##{issue}")} - #{url}" }

      when 'push'
        name = payload[:ref]
        name.slice!(/^refs\/heads\//)
        num = payload[:commits].length
        repo = payload[:repository][:name]
        url = Gitio::shorten payload[:compare]
        user = payload[:sender][:login]
        $channels[payload[:repository][:full_name]].map { |it|
          bot.channel_list.find_ensured(it) }.each do |chan|
          chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} pushed #{Cinch::Formatting.format(:green, num.to_s)} commits to #{Cinch::Formatting.format(:green, name)}: #{url}"
          payload[:commits].take(3).each do |commit|
            chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting::format(:green, commit[:id][0..7])} #{commit[:message]}"
          end
          unless num - 3 < 0
            chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: ...and #{Cinch::Formatting.format(:green, (num - 3).to_s)} more."
          end
        end


      when 'issues'
        action = payload[:action]
        unless /(un)?labeled/ =~ action
          issue = payload[:issue][:number]
          repo = payload[:repository][:name]
          title = payload[:issue][:title]
          url = Gitio::shorten payload[:issue][:html_url]
          user = payload[:sender][:login]
          $channels[payload[:repository][:full_name]].map { |it|
            bot.channel_list.find_ensured(it) }.each { |chan| chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} #{action} issue #{Cinch::Formatting.format(:green, "\##{issue}")}: \"#{title}\" - #{url}" }
        end

      when 'issue_comment'
        url = Gitio::shorten payload[:issue][:html_url]
        issue = payload[:issue][:number]
        user = payload[:comment][:user][:login]
        title = payload[:issue][:title]
        repo = payload[:repository][:name]
        $channels[payload[:repository][:full_name]].map { |it|
          bot.channel_list.find_ensured(it) }.each { |chan| chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{user} commented on issue #{Cinch::Formatting.format(:green, "\##{issue}")}: \"#{title}\" - #{url}" }

      when 'create'
        name = payload[:ref]
        type = payload[:ref_type]
        repo = payload[:repository][:name]
        url = Gitio::shorten payload[:repository][:html_url]
        user = payload[:sender][:login]
        $channels[payload[:repository][:full_name]].map { |it|
          bot.channel_list.find_ensured(it) }.each { |chan| chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} created #{type} #{name}: #{url}" }

      when 'delete'
        name = payload[:ref]
        type = payload[:ref_type]
        repo = payload[:repository][:name]
        url = Gitio::shorten payload[:repository][:html_url]
        user = payload[:sender][:login]
        $channels[payload[:repository][:full_name]].map { |it|
          bot.channel_list.find_ensured(it) }.each { |chan| chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} deleted #{type} #{name}: #{url}" }

      when 'fork'
        repo = payload[:repository][:name]
        url = Gitio::shorten payload[:forkee][:html_url]
        user = payload[:forkee][:owner][:login]
        $channels[payload[:repository][:full_name]].map! { |it|
          bot.channel_list.find_ensured(it) }.each { |chan| chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} forked the repo: #{url}" }

      when 'commit_comment'
        url = Gitio::shorten payload[:comment][:html_url]
        commit = payload[:comment][:commit_id]
        user = payload[:comment][:user][:login]
        repo = payload[:repository][:name]
        $channels[payload[:repository][:full_name]].map { |it|
          bot.channel_list.find_ensured(it) }.each { |chan| chan.msg "[#{Cinch::Formatting.format(:blue, repo)}: #{Cinch::Formatting.format(:orange, user)} commented on commit #{Cinch::Formatting.format(:green, commit)}: #{url}" }
      else
        #bot.channel_list.find('#ElrosBot').msg "unrecognized!: #{payload}"
    end
    204
  end
end