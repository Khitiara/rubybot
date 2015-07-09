require 'twitter'
require 'rubybot/core/command_info'

module Rubybot
  module Plugins
    class Tweet
      include Cinch::Plugin

      def initialize(bot)
        super
        @twitter = Twitter::REST::Client.new do |c|
          c.consumer_key = config[:consumer_key]
          c.consumer_secret = config[:consumer_secret]
          c.access_token = config[:access_token]
          c.access_token_secret = config[:access_token_secret]
        end
      end

      def commands
        [Rubybot::Core::CommandInfo.new('<tweet url>', 'Prints the contents of the given tweet', prefix: false)]
      end

      match %r{.*(https://twitter.com/[^/]+/status/[^/]+)}, use_prefix: false

      def execute(m, uri)
        status = @twitter.status(URI(uri))
        text = status.full_text
        user = status.user.screen_name
        m.reply "@#{user}: #{text}"
      end
    end
  end
end
