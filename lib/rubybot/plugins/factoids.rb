require 'rubybot/plugins/factoids/macros'
require 'rubybot/plugins/factoids/storage'
require 'active_support/core_ext/class/attribute_accessors'

module Rubybot
  module Plugins
    class Factoids
      include Cinch::Plugin
      
      def self.arg_regex
        /([^\s'"]*(?:"[^"]*"|'[^']*'|[^"'\s]+)[^\s'"]*)/
      end
      
      def self.factoid_command_regex
        /([a-zA-Z]+)([^>]*)(?:\s*>\s*((?:[a-zA-Z]+)(?:[^>]*)))?/
      end

      def initialize
        @storage = Factoids::Storage.new
      end

      set prefix: '?'
      match self.factoid_command_regex
      match /\+([a-zA-Z]+).*/, method: :show
      match /\*([a-zA-Z]+)(?: (.+))?/, method: :set

      def set(msg, name, value = nil)
        if @storage.reserved.key? name or Macros.macros.key? name
          msg.reply "#{msg.user.nick}: #{name} is reserved!"
        else
          if value.nil?
            @storage.user.delete name
          else
            @storage.user[name] = value
          end
          save
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
        if res.start_with? '/me '
          msg.action_reply res[4..-1]
        else
          msg.reply res
        end
      end

      def process(msg, prev, command, args, rest)
        if prev.nil? and msg.channel
          prev = bot.logs.channel(msg.channel.name).to_a.reverse.first || ''
        end
        args_s = args.strip
        args   = args_s.split
        if Macros.macros.key? command
          resp = "${#{command}#{args_s.nil? ? '' : "(#{args_s})"}}"
        else
          resp = @storage.factoids[command]
        end
        res = Macros.process msg, resp, msg.user.nick, args, prev
        if not rest.nil?
          match = self.factoid_command_regex.match(rest).to_a.drop 1
          blob  = process msg, res, *match
        else
          blob = res
        end
        blob
      end
    end
  end
end