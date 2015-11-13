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
        args = Shellwords.split command
        case (cmd = args.shift)
        when 'acl'
          case (acl_scmd = args.shift)
          when 'set'
            user, level = *(args.shift(2))
            if user && level
              bot.acl.set user, level.to_i
            else
              msg.channel.msg 'Invalid usage!'
            end
          when 'rem'
            user = args.shift
            if user
              bot.acl.rm user
            else
              msg.channel.msg 'Invalid usage!'
            end
          when 'get'
            user = args.shift
            if user
              msg.channel.msg bot.acl.get user
            else
              msg.channel.msg 'Invalid usage!'
            end
          when 'save'
            begin
              bot.acl.save
            rescue => e
              puts e
              puts e.backtrace
            end
            msg.channel.msg 'Saved successfully'
          else
            msg.channel.msg "Unkown acl subcommand #{acl_scmd}"
          end
        when 'factoid'
          case (fac_scmd = args.shift)
          when 'reserve'
            name = args.shift
            if name
              reserve_factoid name
            else
              msg.channel.msg 'Invalid usage!'
            end
          when 'free'
            name = args.shift
            if name
              free_factoid name
            else
              msg.channel.msg 'Invalid usage!'
            end
          else
            msg.channel.msg "Unkown factoid subcommand #{fac_scmd}"
          end
        else
          msg.channel.msg "Unkown command #{cmd}"
        end
      end
    end
  end
end
