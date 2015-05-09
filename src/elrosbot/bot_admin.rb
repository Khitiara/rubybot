require File.dirname(__FILE__) + '/plugin'
class BotAdmin
  include ElrosBot::Plugin

  set(:prefix => '.')
  match /admin:([a-z]+)(.+)?/

  def execute(msg, command, args=nil)
    return unless bot.acl.auth_or_fail(msg.channel, msg.user)
    case command
      when 'reload'
        bot.reload_conf
      else
        msg.reply 'I dont know how to do that!'
    end
  end
end