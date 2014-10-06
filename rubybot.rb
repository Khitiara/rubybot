require 'rubygems'
require 'bundler/setup'
require 'cinch'
require_relative 'plugins/sed/sed'
require_relative 'plugins/google/google'
require_relative 'plugins/info/info'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = 'irc.esper.net'
    c.channels = %w(#ElrosBot)
    c.nick = 'ElrosGem'
    c.realname = 'ElrosGem'
    c.sasl.username = 'ElrosGem'
    c.sasl.password = '127708'
    c.user = 'ElrosGem'
    c.plugins.plugins =
        [Info,
         Sed,
         Google]
  end
end

bot.start
