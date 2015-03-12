class Sed
  include Cinch::Plugin
  listen_to :channel
  SED_REGEX = /^s\/(.+?)\/(.+?)(\/\S+|\/|$)/
  match SED_REGEX, use_prefix: false

  def listen(m)
    unless m.message =~ SED_REGEX
      log_priv(m.user.nick, m.message) unless m.channel
      log_chan(m.channel.name, m.user.nick, m.message) if m.channel
    end
  end

  def log_priv(nick, message)
    bot.logs.user(nick) << message
  end

  def log_chan(channel, nick, message)
    bot.logs.channel(channel) << {:nick => nick, :message => message}
  end

  def execute(m, matcher, replacement, conditional)
    regex = Regexp.new(matcher, conditional.include?('i'))
    if m.channel
      got = false
      bot.logs.channel(m.channel).to_a.reverse.each { |msg|
        if regex =~ msg[:message]
          out = conditional.include?('g') ? msg[:message].gsub(regex, replacement) : msg[:message].sub(regex, replacement)
          m.reply("#{msg[:nick]}: #{out}")
          got = true
          break
        end
      }
      m.reply("No match for '#{matcher}' in #{m.channel}!") unless got
    else
      got = false
      bot.logs.user(m.user.nick).to_a.reverse.each { |msg|
        if regex =~ msg
          out = conditional.include?('g') ? msg[:message].gsub(regex, replacement) : msg[:message].sub(regex, replacement)
          m.reply("#{m.user.nick}: #{out}")
          got = true
        end
      }
      m.reply("No match for '#{matcher}'!") unless got
    end
  end
end
