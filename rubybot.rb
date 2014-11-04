require 'rubygems'
require 'bundler/setup'
require 'cinch'
require 'json'
require 'sinatra'

$cfg_file = File.read 'config.json'
$config = JSON.parse($cfg_file)

require_relative 'plugins/sed/sed'
require_relative 'plugins/google/google'
require_relative 'plugins/info/info'
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
      config.plugins.options[Cinch::HttpServer] = {
          :host => '0.0.0.0',
          :port => 4567
      }
    end
    # noinspection RubyResolve
    c.plugins.plugins =
        [Info,
         Sed,
         Google,
         Tweet,
         Github]
  end
end

Thread.new {
  $bot.start
}