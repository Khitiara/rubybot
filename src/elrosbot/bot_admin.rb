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
      when 'stop'
        bot.quit args
      when 'conf'
        process_conf(msg, args.split(' '))
      else
        msg.reply 'I dont know how to do that!'
    end
  end

  def process_conf(msg, args)
    unless args.length >= 2
      msg.reply 'Invalid command usage.'
      return
    end
    command = args.shift
    prop    = args.shift
    case command
      when 'set'
        value = args.shift
        if value.nil?
          msg.reply 'Invalid command usage.'
          return
        end
        deep_set(bot.bot_config, prop, value)
        bot.save
      when 'add'
        value = args.shift
        if value.nil?
          msg.reply 'Invalid command usage.'
          return
        end
        deep_add(bot.bot_config, prop, value)
        bot.save
      else
        msg.reply 'Invalid command usage.'
    end
  end

  def deep_add(c, k, v)
    segments = k.split('.')
    object   = c
    segments.each do |s|
      # call the setter for the last segment on the previous segment's object
      # or the main config object if there was only one segment
      if s == segments.last
        val = object.send s || []
        val << v
        object.send "#{s}=", val
        # for all segments but the last, call the getter and obtain a nested config object
      else
        object = object.send s
      end
    end
  end

  def deep_set(c, k, v)
    segments = k.split('.')
    object   = c
    segments.each do |s|
      # call the setter for the last segment on the previous segment's object
      # or the main config object if there was only one segment
      if s == segments.last
        object.send "#{s}=", v
        # for all segments but the last, call the getter and obtain a nested config object
      else
        object = c.send s
      end
    end
  end
end