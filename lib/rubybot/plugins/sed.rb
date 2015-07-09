module Rubybot
  module Plugins
    class Sed
      include Cinch::Plugin
      listen_to :channel
      SED_REGEX = %r{^s/(.+?)/(.+?)(/\S+|/|$)}
      match SED_REGEX, use_prefix: false

      def listen(m)
        return if m.message =~ SED_REGEX || !m.channel
        log m.channel.name, m.user.nick, m.message
      end

      def log(channel, nick, message)
        bot.logs.channel(channel) << { nick: nick, message: message }
      end

      def execute(m, matcher, replacement, conditional)
        regex = Regexp.new(matcher, conditional.include?('i'))
        is_global = conditional.include? 'g'
        got = false
        bot.logs.channel(m.channel).to_a.reverse_each do |msg|
          next unless regex =~ msg[:message]
          out = is_global ? msg[:message].gsub(regex, replacement) : msg[:message].sub(regex, replacement)
          m.reply("#{msg[:nick]}: #{out}")
          got = true
          break
        end
        m.reply("No match for '#{matcher}' in #{m.channel}!") unless got
      end
    end
  end
end
