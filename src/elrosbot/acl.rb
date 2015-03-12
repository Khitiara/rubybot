require 'cinch/helpers'
module ElrosBot
  class Acl
    include Cinch::Helpers
    attr_reader :bot

    def initialize(bot)
      @bot    = bot
      levels  = bot.bot_config['acl'] || {}
      @levels = levels.merge({ "#{bot.owner.to_s}": 0 })
    end

    def authed?(user, level=0)
      userlevel = @levels[user.name] || -1
      userlevel >= 0 and userlevel <= level
    end

    def auth_or_fail(chan, user, level=0, msg="#{user.nick} is not permitted to do that!")
      authed = authed? user, level
      chan.msg msg unless authed
      authed
    end

    def save
      bot.bot_config['acl'] = @levels
      bot.save
    end
  end
end