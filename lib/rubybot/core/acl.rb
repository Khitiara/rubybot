require 'cinch/helpers'
require 'active_support/core_ext/hash/indifferent_access'

module Rubybot
  module Core
    class Acl
      include Cinch::Helpers
      attr_reader :bot
      attr_reader :levels

      def initialize(bot)
        @bot    = bot
        @levels = (bot.bot_config[:acl] || {}).merge(bot.owner.to_s => 0).with_indifferent_access
      end

      def set(user, level)
        fail 'Not allowed' if user == bot.owner.to_s || level < 1
        @levels[user] = level
      end

      def get(user)
        @levels[user] || -1
      end

      def rm(user)
        fail 'Not allowed' if user == bot.owner.to_s
        @levels.delete user
      end

      def authed?(user, level = 0)
        userlevel = @levels[user] || -1
        userlevel >= 0 && userlevel <= level
      end

      def auth_or_fail(chan, user, level = 0, msg = "#{user.nick} is not permitted to do that!")
        authed = authed? user.name, level
        chan.msg msg unless authed
        authed
      end

      def save
        bot.bot_config[:acl] = @levels.reject { |k, _| k == bot.owner.to_s }
        bot.save
      end
    end
  end
end
