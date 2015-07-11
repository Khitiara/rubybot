require 'rubybot/plugins/factoids/macros'
require 'shellwords'
require 'rubybot/plugins/factoids/storage'
require 'active_support/core_ext/class/attribute_accessors'
require 'rubybot/core/command_info'

module Rubybot
  module Plugins
    class Factoids
      include Cinch::Plugin

      attr_reader :storage

      def self.factoid_command_regex
        /([a-zA-Z]+)([^>]*)(?:>\s+(.+))?/
      end

      def initialize(bot)
        super
        @storage = Factoids::Storage.new config[:filename]
      end

      def commands
        [
          Rubybot::Core::CommandInfo.new('?factoid show <name>', 'Shows how the factoid is defined'),
          Rubybot::Core::CommandInfo.new('?factoid set <name> [<definition>]',
                                         '(Re)defines the factoid, or undefines it if <definition> is empty'),
          Rubybot::Core::CommandInfo.new('?+<name>', 'Shows how the factoid is defined'),
          Rubybot::Core::CommandInfo.new('?*<name> [<definition>]',
                                         '(Re)defines the factoid, or undefines it if <definition> is empty'),
          Rubybot::Core::CommandInfo.new('?<name> [> <other name>]',
                                         'Prints the factoid (or executes it, in the case of macros).')
        ] | factoid_commands | macro_commands
      end

      def factoid_commands
        @storage.factoids.map do |f|
          Rubybot::Core::CommandInfo.new '?' + f.first, "Prints the contents for the factoid '#{f.first}'"
        end
      end

      def macro_commands
        Macros.macros.map do |m|
          Rubybot::Core::CommandInfo.new '?' + m.first, "Runs and prints the result of the macro '#{m.first}'"
        end
      end

      set prefix: '?', plugin_name: 'factoids'
      match factoid_command_regex
      match(/(?:\+|factoid show )([a-zA-Z]+).*/, method: :show)
      match(/(?:\*|factoid set )([a-zA-Z]+)(?: (.+))?/, method: :set)

      def set(msg, name, value = nil)
        if @storage.reserved.key?(name) || Macros.macros.key?(name)
          msg.reply "#{msg.user.nick}: #{name} is reserved!"
        else
          if value.nil?
            @storage.user.delete name
          else
            @storage.user[name] = value
          end
          @storage.save
        end
      end

      def show(msg, name)
        if @storage.factoids.key?(name)
          msg.reply @storage.factoids[name]
        elsif Macros.macros.key? name
          msg.reply Macros.macros[name].name || 'Macro'
        end
      end

      def execute(msg, command, args, rest)
        res = process(msg, '', command, args, rest)
        return if res.nil?
        if res.start_with? '/me '
          msg.action_reply res[4..-1]
        else
          msg.reply res
        end
      end

      def process(msg, prev, command, args, rest)
        if prev.nil? && msg.channel
          prev = bot.logs(msg.channel.name).to_a.reverse.first || ''
        end
        args_s = args.strip
        if Macros.macros.key? command
          res = Macros.run(msg, msg.user.nick, command, args_s)
        else
          resp = @storage.factoids[command]
          return if resp.nil?
          res = Macros.process msg, resp, msg.user.nick, args_s, prev
        end
        if !rest.nil?
          match = Factoids.factoid_command_regex.match(rest).to_a.drop 1
          blob = process msg, res, *match
        else
          blob = res
        end
        blob
      end
    end
  end
end
