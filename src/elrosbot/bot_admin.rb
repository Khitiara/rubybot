require File.dirname(__FILE__) + '/plugin'
require 'commander'
require 'shellwords'

class BotAdmin
  include ElrosBot::Plugin
  include Cinch::Plugin

  match /admin\s+(.+)/

  def execute(msg, command)
    return unless bot.acl.auth_or_fail(msg.channel, msg.user)
    argv   = Shellwords.split command
    parser = Commander::Runner.new argv
    parser.program :name, 'RubyBot Admin Module'
    parser.program :version, '1.0.0'
    parser.program :description, 'IRC Bot'
    parser.command :'acl set' do |c|
      c.action do |args, _|
        user, level = *(args.shift(2))
        if user and level
          bot.acl.set user, level.to_i
        else
          msg.channel.msg 'Invalid usage!'
        end
      end
    end
    parser.command :'acl rem' do |c|
      c.action do |args, _|
        user= args.shift
        if user
          bot.acl.rm user
        else
          msg.channel.msg 'Invalid usage!'
        end
      end
    end
    parser.command :'acl get' do |c|
      c.action do |args, _|
        user= args.shift
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
    parser.run!
  end
end