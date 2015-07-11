require 'cinch/formatting'

class String
  def format(*settings)
    Cinch::Formatting.format(*settings, self)
  end
end

module Rubybot
  module Core
    class GithubMessageFormatter
      def self.format(key, hash)
        send 'format_' + key.to_s, hash
      end

      def self.format_pull_request(hash)
        message_item hash[:repo], "##{hash[:number]}", hash[:user], "#{hash[:action]} \"#{hash[:title]}\"", hash[:url]
      end

      def self.format_review_comment(hash)
        [
          format_pull_request(hash.merge action: 'reviewed'),
          hash[:body].lines.first
        ]
      end

      def self.format_push_oneline(hash)
        message(hash[:repo], hash[:user],
                "pushed #{num.to_s.format :green} commits to #{hash[:ref].slice(%r{^refs/heads/}).format :green}",
                hash[:url])
      end

      def self.format_push(hash)
        num  = hash[:commits].length

        response = [format_push_oneline(hash)]
        response |= hash[:commits].take(3).map do |commit|
          message_item(hash[:repo], commit[:id][0..7], nil, commit[:message].lines.first, commit[:url])
        end
        response << "[#{hash[:repo].format :blue}]: ...and #{(num - 3).to_s.format :green} more." if num - 3 > 0
        response
      end

      def self.format_issue(hash)
        message_item hash[:repo], "##{hash[:number]}", hash[:user], hash[:title], hash[:url]
      end

      def self.format_issues(hash)
        format_pull_request hash
      end

      def self.format_issue_comment(hash)
        line = hash[:body].lines.first
        body = line[0, 400]
        body += '...' if line.length >= 400
        body = '"' + body + '"'
        [
          format_issues(hash.merge action: 'commented on'),
          body
        ]
      end

      def self.format_create(hash)
        message hash[:repo], hash[:user], "created #{hash[:type]} #{hash[:name]}", hash[:url]
      end

      def self.format_delete(hash)
        message hash[:repo], hash[:user], "deleted #{hash[:type]} #{hash[:name]}", hash[:url]
      end

      def self.format_fork(hash)
        message hash[:repo], hash[:user], 'forked the repo', hash[:url]
      end

      def self.format_commit_comment(hash)
        [
          message_item(hash[:repo], hash[:commit][0..7], hash[:user], 'commented', hash[:url]),
          hash[:body].lines.first
        ]
      end

      def self.format_status(hash)
        state = hash[:state]
        unless state == 'pending'
          res = message_item hash[:repo], hash[:commit][0..7], nil, hash[:description], hash[:url]
          return res if state == 'success'
          [
            res,
            "Blame: #{hash[:user]}"
          ]
        end
      end

      def self.message(repo, user, action, url)
        "[#{repo.to_s.format :blue}]: #{user.to_s.format :orange} #{action}: #{Gitio.shorten url}"
      end

      def self.message_item(repo, item, user, action, url)
        message "#{repo} #{item.to_s.format :green}", user, action, url
      end
    end
  end
end
