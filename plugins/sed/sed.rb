class Sed
  include Cinch::Plugin
  listen_to :channel
  SED_REGEX = /^s\/(.+?)\/(.+?)(\/\S+|\/|$)/
  match SED_REGEX, :use_prefix => false
  def listen(m)
    unless m.message =~ SED_REGEX
      log_user(m.user.nick)
      set_last_message(m.user.nick, m.message)
      set_last_channel_message(m.channel.name, m.message) if m.channel
    end
  end
  def execute(m, matcher, replacement, conditional)
    count = (conditional =~ /([0-9]+)/ ? $1.to_i : 1)
    if conditional.include? 'c'
      if m.channel
        original = get_channel_message(m.channel.name, count)
      else
        m.reply 'You cannot specify the channel when PMing'
        return
      end
    else
      original = get_user_message(m.user.nick, count)
    end
    if original.nil?
      m.reply 'You need to say something first.'
      return
    end
    if conditional.include? 'g'
      replacement = original.gsub(matcher, replacement)
    else
      replacement = original.sub(matcher, replacement)
    end
    if conditional.include? 't'
      m.reply "#{replacement}"
    else
      m.reply "#{m.user.nick} meant '#{replacement}'"
    end
  end
  def set_last_message(user, message)
    @bot.database.lpush("user:#{user}:messages", message)
    @bot.database.ltrim("user:#{user}:messages", 0, 1000)
  end
  def set_last_channel_message(channel, message)
    @bot.database.lpush("channel:#{channel}:messages", message)
    @bot.database.ltrim("channel:#{channel}:messages", 0, 1000)
  end
  def log_user(user)
    unless @bot.database.sismember('users_logged', user)
      @bot.database.sadd("users_logged", user)
    end
  end
  def get_user_message(user, scrollback = 1)
    index = scrollback - 1
    @bot.database.lrange("user:#{user}:messages", index, index).first
  end
  def get_channel_message(channel, scrollback = 1)
    index = scrollback - 1
    @bot.database.lrange("channel:#{channel}:messages", index, index).first
  end
end
