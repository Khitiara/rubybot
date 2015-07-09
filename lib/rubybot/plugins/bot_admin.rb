require 'commander'
require 'shellwords'
require 'rubybot/core/command_info'

module Rubybot
  module Plugins
    class BotAdmin
      include Cinch::Plugin

      set prefix: '?', plugin_name: 'admin'
      match(/admin\s+(.+)/)

      def commands
        [
          Rubybot::Core::CommandInfo.new('?admin acl set <user> <level>', 'Gives <user> access level <level>'),
          Rubybot::Core::CommandInfo.new('?admin acl rem <user>', 'Removes any access level from <user>'),
          Rubybot::Core::CommandInfo.new('?admin acl get <user>', 'Prints the access level for <user>'),
          Rubybot::Core::CommandInfo.new('?admin acl save', 'Saves the current user/access levels'),
          Rubybot::Core::CommandInfo.new('?admin factoid reserve <name>', 'Reserves the given factoid <name>'),
          Rubybot::Core::CommandInfo.new('?admin factoid free <name>', 'Frees the given factoid <name>')
        ]
      end

      def execute(msg, command) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity
        return unless bot.acl.auth_or_fail(msg.channel, msg.user)
        parser = Commander::Runner.new Shellwords.split command
        parser.program :name, 'RubyBot Admin Module'
        parser.program :version, '1.0.0'
        parser.program :description, 'IRC Bot'
        parser.command :'acl set' do |c|
          c.action do |args, _|
            user, level = *(args.shift(2))
            if user && level
              bot.acl.set user, level.to_i
            else
              msg.channel.msg 'Invalid usage!'
            end
          end
        end
        parser.command :'acl rem' do |c|
          c.action do |args, _|
            user = args.shift
            if user
              bot.acl.rm user
            else
              msg.channel.msg 'Invalid usage!'
            end
          end
        end
        parser.command :'acl get' do |c|
          c.action do |args, _|
            user = args.shift
            if user
              msg.channel.msg bot.acl.get user
            else
              msg.channel.msg 'Invalid usage!'
            end
          end
        end
        parser.command :'acl save' do |c|
          c.action do |_, _|
            begin
              bot.acl.save
            rescue => e
              puts e
              puts e.backtrace
            end
            msg.channel.msg 'Saved successfully'
          end
        end
        parser.command :'factoid reserve' do |c|
          c.action do |args, _|
            name = args.shift
            if name
              reserve_factoid name
            else
              msg.channel.msg 'Invalid usage!'
            end
          end
        end
        parser.command :'factoid free' do |c|
          c.action do |args, _|
            name = args.shift
            if name
              free_factoid name
            else
              msg.channel.msg 'Invalid usage!'
            end
          end
        end
        parser.always_trace!
        begin
          parser.run!
        rescue InvalidCommandError
          msg.reply 'I dont know how to do that!'
        end
      end
    end
  end
end
