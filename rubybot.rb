require 'rubygems'
require 'bundler/setup'
require 'cinch'
require 'json'
require 'timers'
require 'active_support/time'

$timers = Timers::Group.new

$cfg_file = File.read 'config.json'
$config = JSON.parse($cfg_file)

require_relative 'plugins/sed/sed'
require_relative 'plugins/google/google'
# require_relative 'plugins/info/info'
require_relative 'plugins/factoids/factoids'
require_relative 'plugins/tweet/tweet'
require_relative 'plugins/github/github'

$bot = Cinch::Bot.new do
  configure do |c|
    $config['bot'].each do |k, v|
      segments = k.split('.')
      object = c
      segments.each do |s|
        # call the setter for the last segment on the previous segment's object
        # or the main config object if there was only one segment
        if s == segments.last
          object.send s + '=', v
          # for all segments but the last, call the getter and obtain a nested config object
        else
          object = c.send s
        end
      end
    end
    # noinspection RubyResolve
    c.plugins.plugins =
        [Factoids,
         # Info,
         Sed,
         Google,
         Tweet,
         Github,
         Cinch::HttpServer]
    c.plugins.options[Cinch::HttpServer] = {
        host: '0.0.0.0',
        port: 4567
    }
  end
end

fix_nick = $timers.every(1.hours) do
  $bot.nick = $config['bot']['nick']
end

$bot.start
fix_nick.cancel