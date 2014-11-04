require_relative '../http/http_server'

class Github
  include Cinch::Plugin
  extend Cinch::HttpServer::Verbs

  require 'gitio'

  post '/gh-hook', :agent => /GitHub-Hookshot\/.*/ do
    payload_raw = body.read
    payload = JSON.parse(payload_raw, {:symbolize_names => true})
    event = env['X_Github_Event']
    case event
      when 'pull_request'
        issue = payload[:number]
        action = payload[:action]
        repo = payload[:repository][:name]
        title = payload[:pull_request][:title]
        url = Gitio::shorten payload[:pull_request][:html_url]
        user = payload[:sender][:login]
        bot.channels.each { |chan| chan.msg "[#{repo}]: #{user} #{action} pull request \##{issue}: \"#{title}\": #{url}" }

      when 'pull_request_review_comment'
        url = Gitio::shorten payload[:comment][:html_url]
        issue = payload[:pull_request][:number]
        user = payload[:comment][:user][:login]
        repo = payload[:repository][:name]
        bot.channels.each { |chan| chan.msg "[#{repo}]: #{user} reviewed pull request \##{issue}: #{url}" }

      when 'push'
        name = payload[:ref]
        num = payload[:size]
        repo = payload[:repository][:name]
        url = Gitio::shorten payload[:repository][:html_url]
        user = payload[:sender][:login]
        bot.channels.each { |chan| chan.msg "[#{repo}]: #{user} pushed #{num} commits to #{name}: #{url}" }

      when 'issues'
        action = payload[:action]
        unless /(un)?labeled/ =~ action
          issue = payload[:issue][:number]
          repo = payload[:repository][:name]
          title = payload[:issue][:title]
          url = Gitio::shorten payload[:issue][:html_url]
          user = payload[:sender][:login]
          bot.channels.each { |chan| chan.msg "[#{repo}]: #{user} #{action} issue \##{issue}: \"#{title}\": #{url}" }
        end

      when 'issue_comment'
        url = Gitio::shorten payload[:issue][:html_url]
        issue = payload[:issue][:number]
        user = payload[:comment][:user][:login]
        repo = payload[:repository][:name]
        bot.channels.each { |chan| chan.msg "[#{repo}]: #{user} commented on issue \##{issue}: #{url}" }

      when 'create'
        name = payload[:ref]
        type = payload[:ref_type]
        repo = payload[:repository][:name]
        url = Gitio::shorten payload[:repository][:html_url]
        user = payload[:sender][:login]
        bot.channels.each { |chan| chan.msg "[#{repo}]: #{user} created #{type} #{name}: #{url}" }

      when 'delete'
        name = payload[:ref]
        type = payload[:ref_type]
        repo = payload[:repository][:name]
        url = Gitio::shorten payload[:repository][:html_url]
        user = payload[:sender][:login]
        bot.channels.each { |chan| chan.msg "[#{repo}]: #{user} deleted #{type} #{name}: #{url}" }

      when 'fork'
        repo = payload[:repository][:name]
        url = Gitio::shorten payload[:forkee][:html_url]
        user = payload[:forkee][:owner][:login]
        bot.channels.each { |chan| chan.msg "[#{repo}]: #{user} forked the repo: #{url}" }

      when 'commit_comment'
        url = Gitio::shorten payload[:comment][:html_url]
        commit = payload[:comment][:commit_id]
        user = payload[:comment][:user][:login]
        repo = payload[:repository][:name]
        bot.channels.each { |chan| chan.msg "[#{repo}]: #{user} commented on commit #{commit}: #{url}" }
      else
        # No-OP
    end
    204
  end
end