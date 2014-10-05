require 'rubygems'
require 'bundler/setup'
require 'cinch'
require 'plugins/sed/sed'
require 'plugins/google/google'
require 'plugins/info/info'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = 'irc.esper.net'
    c.channels = %w(#MultiMC #ElrosBot)
    c.nick = 'ElrosGem'
    c.sasl.username = 'ElrosGem'
    c.sasl.password = '127708'
    c.user = 'ElrosGem'
    c.plugins.plugins = [Sed, Google, Info]
  end
end

bot.start
