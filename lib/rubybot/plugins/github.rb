require 'rubybot/plugins/http_server/http_server'
require 'gitio'
require 'cinch/formatting'
require 'cinch/helpers'
require 'yajl'

def get_repo_owner(repo)
  repo[:repository][:owner][:login] || repo[:repository][:owner][:name]
end

# noinspection RubyResolve

def get_repos(repo)
  conf  = bot.bot_config['github_repos']
  repos = []
  if conf.has_key? repo[:full_name]
    repos += conf[repo[:full_name]]
  end
  if conf.has_key? "#{get_repo_owner(repo)}/"
    repos += conf["#{get_repo_owner(repo)}/"]
  end
  repos
end

module Rubybot
  module Plugins
    class Github
      extend Cinch::HttpServer::Verbs
      include Cinch::Plugin

      before do
        request.body.rewind
        read             = request.body.read
        @request_payload = Yajl::Parser.parse(read, symbolize_keys: true)
      end

      post '/gh-hook', :agent => /GitHub-Hookshot\/.*/ do
        payload = @request_payload
        event   = request.env['HTTP_X_GITHUB_EVENT']
        case event
          when 'pull_request'
            action = payload[:action]
            unless /(un)?labeled/ =~ action
              issue = payload[:number]
              repo  = payload[:repository][:name]
              title = payload[:pull_request][:title]
              url   = Gitio::shorten payload[:pull_request][:html_url]
              user  = payload[:sender][:login]
              get_repos(payload).map do |it|
                bot.channel_list.find(it)
              end.each do |chan|
                chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} #{action} pull request #{Cinch::Formatting.format(:green, "\##{issue}")}: \"#{title}\" - #{url}"
              end
            end
          when 'pull_request_review_comment'
            url   = Gitio::shorten payload[:comment][:html_url]
            issue = payload[:pull_request][:number]
            user  = payload[:comment][:user][:login]
            repo  = payload[:repository][:name]
            get_repos(payload).map do |it|
              bot.channel_list.find(it)
            end.each do |chan|
              chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} reviewed pull request #{Cinch::Formatting.format(:green, "\##{issue}")} - #{url}"
            end
          when 'push'
            name = payload[:ref]
            name.slice!(/^refs\/heads\//)
            num  = payload[:commits].length
            repo = payload[:repository][:name]
            url  = Gitio::shorten payload[:compare]
            user = payload[:sender][:login]
            get_repos(payload).map do |it|
              puts it
              bot.channel_list.find(it)
            end.each do |chan|
              chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} pushed #{Cinch::Formatting.format(:green, num.to_s)} commits to #{Cinch::Formatting.format(:green, name)}: #{url}"
              payload[:commits].take(3).each do |commit|
                body = commit[:message].lines[0]
                chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting::format(:green, commit[:id][0..7])} #{body}"
              end
              if num - 3 > 0
                chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: ...and #{Cinch::Formatting.format(:green, (num - 3).to_str)} more."
              end
            end

          when 'issues'
            action = payload[:action]
            unless /(un)?labeled/ =~ action
              issue = payload[:issue][:number]
              repo  = payload[:repository][:name]
              title = payload[:issue][:title]
              url   = Gitio::shorten payload[:issue][:html_url]
              user  = payload[:sender][:login]
              get_repos(payload).map do |it|
                bot.channel_list.find(it)
              end.each do |chan|
                chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} #{action} issue #{Cinch::Formatting.format(:green, "\##{issue}")}: \"#{title}\" - #{url}"
              end
            end

          when 'issue_comment'
            url   = Gitio::shorten payload[:issue][:html_url]
            issue = payload[:issue][:number]
            user  = payload[:comment][:user][:login]
            title = payload[:issue][:title]
            repo  = payload[:repository][:name]
            get_repos(payload).map do |it|
              bot.channel_list.find(it)
            end.each do |chan|
              chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} commented on issue #{Cinch::Formatting.format(:green, "\##{issue}")}: \"#{title}\" - #{url}"
            end

          when 'create'
            name = payload[:ref]
            type = payload[:ref_type]
            repo = payload[:repository][:name]
            url  = Gitio::shorten payload[:repository][:html_url]
            user = payload[:sender][:login]
            get_repos(payload).map do |it|
              bot.channel_list.find(it)
            end.each do |chan|
              chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} created #{type} #{name}: #{url}"
            end

          when 'delete'
            name = payload[:ref]
            type = payload[:ref_type]
            repo = payload[:repository][:name]
            url  = Gitio::shorten payload[:repository][:html_url]
            user = payload[:sender][:login]
            get_repos(payload).map do |it|
              bot.channel_list.find(it)
            end.each do |chan|
              chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} deleted #{type} #{name}: #{url}"
            end

          when 'fork'
            repo = payload[:repository][:name]
            url  = Gitio::shorten payload[:forkee][:html_url]
            user = payload[:forkee][:owner][:login]
            get_repos(payload).map do |it|
              bot.channel_list.find(it)
            end.each do |chan|
              chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} forked the repo: #{url}"
            end

          when 'commit_comment'
            url    = Gitio::shorten payload[:comment][:html_url]
            commit = payload[:comment][:commit_id]
            user   = payload[:comment][:user][:login]
            repo   = payload[:repository][:name]
            get_repos(payload).map do |it|
              bot.channel_list.find(it)
            end.each do |chan|
              chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{Cinch::Formatting.format(:orange, user)} commented on commit #{Cinch::Formatting.format(:green, commit)}: #{url}"
            end

          when 'status'
            state = payload[:state]
            unless state == 'pending'
              repo  = payload[:repository][:name]
              url   = payload[:target_url]
              desc  = payload[:description]
              extra = ''
              unless state == 'success'
                extra = " Blame: #{payload[:commit][:commit][:author][:name]}"
              end
              get_repos(payload).map do |it|
                bot.channel_list.find(it)
              end.each do |chan|
                chan.msg "[#{Cinch::Formatting.format(:blue, repo)}]: #{desc}: #{url}#{extra}"
              end
            end
          else
            # No-op
        end
        204
      end
    end
  end
end
