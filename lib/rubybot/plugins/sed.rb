require 'rubybot/core/command_info'

module Rubybot
  module Plugins
    class Sed
      include Cinch::Plugin
      listen_to :channel
      SED_REGEX = %r{^s/(.+?)/(.+?)(/\S+|/|$)}
      set plugin_name: 'sed'
      match SED_REGEX, use_prefix: false

      def commands
        help = <<HELP
Replaces the most recent occurance of <old> with <new>.

Append 'g' to replace all occurances in the found message.
Append 'i' to be case insensitive.
HELP
        [Rubybot::Core::CommandInfo.new('s/<old>/<new>/[g][i]',
                                        'Replaces the most recent occurance of <old> with <new>',
                                        prefix: false,
                                        help_long: help)]
      end

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
