require 'rufus-lua'

require File.dirname(__FILE__) + '/../factoids/macro'
require File.dirname(__FILE__) + '/../../plugins/factoids/factoids'

class Lua < Macro
  def run(m, args, code, _, nick)
    lua            = Rufus::Lua::State.new
    lua['bot']     = m.bot.nick
    lua['sender']  = nick
    lua['channel'] = m.channel.name
    lua['ioru']    = args[0] || nick
    lua['args']    = args
    lua['users']   = m.channel.users.keys.collect { |it| it.nick }
    lua.function 'exec', to_ruby: true do |command, *more|
      if factoids.key? command or Macros.macros.key? command
        begin
          Macros::process(m, resp(command, more), nick, more, handle(m, rest)) || ''
        rescue MacroSemanticError => e
          "Lua: Macro Semantics Error: #{e.msg}"
        rescue Exception => e
          debug "#{e.message}\n#{e.backtrace.join("\n")}"
          e.message
        end
      end
    end
    begin
      return lua.eval code
    rescue Exception => e
      return e.message
    end
  end
end
Macros.register Lua