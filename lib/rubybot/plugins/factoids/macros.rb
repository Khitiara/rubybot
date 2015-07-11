require 'rubybot/plugins/factoids/macro_semantic_error'
require 'rubybot/plugins/factoids/macro'
require 'shellwords'
require 'ostruct'
require 'erb'

module Rubybot
  module Plugins
    class Factoids
      class Macros
        class << self
          attr_accessor :macros
        end

        class HelpMacro
          def run(message, _, args, _, _)
            if args.empty?
              message.user.notice message.bot.bot_config[:info]
              message.user.notice "Available plugins: #{message.bot.plugins.map { |p| p.class.plugin_name }.join ', '}"
              message.user.notice 'Use ?help <plugin> for a list of commands for a plugin.'
              message.user.notice 'Use ?help <start of command> for help on a specific command.'
            else
              commands(message, args).each do |cmd|
                message.user.notice cmd.plugin.class.plugin_name + ': ' + cmd.command + ': ' + cmd.help_short
                next unless args != '' && cmd.command.start_with?(args) && cmd.help_long
                message.user.notice cmd.help_long.lines.map { |l| '    ' + l }.join "\n"
              end
            end

            'Replying with notice'
          end

          private

          def commands(message, arg)
            plugin = message.bot.plugins.find { |p| p.class.plugin_name == arg }
            if plugin.nil?
              message.bot.plugins.map do |plugin|
                commands_for plugin, message.channel
              end.flatten.find_all { |c| c.command.start_with? arg }
            else
              commands_for plugin, message.channel
            end
          end

          def commands_for(plugin, channel)
            return [] unless plugin.respond_to? :commands
            case plugin.class.instance_method(:commands).arity
              when 0
                plugin.commands
              when 1
                plugin.commands channel
              else
                []
            end.each do |cmd|
              cmd.plugin = plugin
            end
          end
        end

        self.macros = {
            'urlencode' => Macro.implement do |_, _, a, _, _|
              CGI.escape a
            end,
            'list' => Macro.implement do |m, _, _, args, _|
              unless args.length == 0
                fail MacroSemanticError, 'List macro takes no arguments!'
              end
              storage = m.bot.plugins.find { |p| p.class.plugin_name == 'factoids' }.storage
              list = [storage.reserved.keys.map { |it| "#{it} (r)" }, storage.user.keys.map { |it| "#{it} (u)" }, macros.keys.map { |it| "#{it} (m)" }].flatten.sort_by { |word| word.downcase }.join(', ')
              "Factoids (m -> macro, r -> reserved, u -> user): #{list}"
            end,
            'wget' => Macro.implement do |_, _, _, args, _|
              unless args.length == 1
                fail MacroSemanticError, 'Wget macro takes exactly one arguments!'
              end
              require 'net/http'

              url = args[0]

              res = Net::HTTP.get_response(URI(url))
              res.body
            end,
            'splitjoin' => Macro.implement do |_, _, _, args, _|
              fail MacroSemanticError, 'Call macro takes three arguments!' unless args.length == 3
              split = args.shift
              join = args.shift
              blob = args.shift
              blob.split(split).join(join)
            end,
            'call' => Macro.implement do |m, _, _, args, nick|
              unless args.length >= 1
                fail MacroSemanticError, 'Call macro takes at least one argument!'
              end
              name = args.shift
              if Macros.macros.key? name
                Macros.run(m, nick, name, Shellwords.join(args))
              else
                Macros.process(m, m.bot.plugins.find { |p| p.class.plugin_name == 'factoids' }.storage.factoids[name], nick, Shellwords.join(args))
              end
            end,
            'selrand' => Macro.implement do |_, _, _, args, _|
              unless args.length >= 1
                fail MacroSemanticError, 'selrand macro takes at least one argument!'
              end
              args[rand(args.length)]
            end,
            'echo' => Macro.implement do |_, _, args, _, _|
              args
            end,
            'roll' => Macro.implement do |_, _, args, _, nick|
              blob = /(?:(?:(?'times'\d+)#)?(?'num'\d+))?d(?'sides'\d+)(?:(?'mod'[+-])(?'modnum'\d+))?/.match args
              repeats = blob['times'].to_i || 1
              rolls = blob['num'].to_i || 1
              sides = blob['sides'].to_i
              offset_op = blob['mod']
              offset = blob['modnum']
              repeats = 1 if repeats < 1
              rolls = 1 if rolls < 1
              total = 0
              repeats.times do
                rolls.times do
                  total += rand(sides.to_i) + 1
                end
                total = total.send(offset_op, offset.to_i) if offset_op
              end

              "#{nick}: You rolled #{args} -> #{total}"
            end,
            'help' => HelpMacro.new
        }

        # noinspection RubyResolve
        def self.process(m, resp, nick, args_s, prev = '')
          args = Shellwords.split args_s
          namespace = Class.new do
            def get_binding
              binding
            end
          end
          namespace.send(:define_method, 'ioru') do
            args.shift || nick
          end
          namespace.send(:define_method, 'me') do
            nick
          end
          namespace.send(:define_method, 'args') do
            args
          end
          namespace.send(:define_method, 'args_s') do
            args_s
          end
          namespace.send(:define_method, 'prev') do
            prev
          end
          macros.each do |k, _|
            namespace.send(:define_method, k) do |*a|
              Macros.run(m, nick, k, Shellwords.join(a))
            end
          end
          ERB.new(resp).result(namespace.new.get_binding)
        end

        def self.register(clazz, name = nil)
          macros[name || clazz.name.downcase] = clazz.new
        end

        def self.macro_alias(n, a)
          macros[a] = macros[n]
        end

        def self.run(m, nick, name, macro_args_s)
          macro_args = Shellwords.split(macro_args_s)
          macro = macros[name]
          args = Shellwords.split(macro_args_s)
          macro.run(m, args, macro_args_s, macro_args, nick)
        end

        macro_alias('wget', 'curl')
      end
    end
  end
end
