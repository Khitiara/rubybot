require 'json'

$lists_filename = 'pinglists.json'
file = File.read($lists_filename)
$pinglists = JSON.parse(file)

def save_pings
  text = JSON.pretty_unparse $pinglists
  File.open($lists_filename, 'w') do |file|
    file.puts text
  end
end

class PingLists
  include Cinch::Plugin
  set(:prefix => '?')

  match /s ([a-zA-Z0-9_]+)(?: ([a-zA-Z0-9_]+))?/, method: :subscribe
  match /p ([a-zA-Z0-9_]+)(?: (.+))?/, method: :ping
  match /u ([a-zA-Z0-9_]+)(?: ([a-zA-Z0-9_]+))?/, method: :unsub
  match /([a-zA-Z0-9_]+):.*/, use_prefix: false, method: :ping2

  def subscribe(msg, list, user = nil)
    chan = msg.channel
    return unless chan

    if user.nil?
      unless $pinglists[list]
        $pinglists[list] = [];
      end

      $pinglists[list] << msg.user.nick
    elsif @bot.acl.authed? msg.user, 1
      unless $pinglists[list]
        $pinglists[list] = [];
      end

      $pinglists[list] << user
    else
      msg.reply 'You are not allowed to subscribe others!'
    end

    save_pings
  end

  def ping(msg, list, text = nil)
    chan = msg.channel
    return unless chan

    unless $pinglists[list]
      $pinglists[list] = [];
    end

    return if $pinglists[list].empty?

    return unless @bot.acl.auth_or_fail chan, msg.user, 2, "#{msg.user.nick} is not allowed to ping lists!"

    first = $pinglists[list].join ', '

    msg.reply "#{first}: #{text || '^'}"
  end

  def unsub(msg, list, user = nil)
    chan = msg.channel
    return unless chan

    if user.nil?
      unless $pinglists[list]
        $pinglists[list] = [];
      end

      $pinglists[list].delete msg.user.nick
    elsif @bot.acl.authed? msg.user, 1
      unless $pinglists[list]
        $pinglists[list] = [];
      end

      $pinglists[list].delete user
    else
      msg.reply 'You are not allowed to unsubscribe others!'
    end

    save_pings
  end

  def ping2(msg, list)
    chan = msg.channel
    return unless chan

    unless $pinglists[list]
      $pinglists[list] = [];
    end

    return if $pinglists[list].empty?

    return unless @bot.acl.auth_or_fail chan, msg.user, 2, "#{msg.user.nick} is not allowed to ping lists!"

    first = $pinglists[list].join ', '

    msg.reply "#{first}: ^"
  end
end