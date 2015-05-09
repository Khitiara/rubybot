require 'bundler/setup'
require 'cinch'
require_relative 'src/elrosbot'
require 'json'

Dir.foreach('plugins') do |item|
  next if item == '.' or item == '..'
  # noinspection RubyResolve
  require File.expand_path("plugins/#{item}/#{item}.rb")
end

$bot = ElrosBot::Bot.new(
    {
        cfg_filename: 'config.json',
        http_host:    '0.0.0.0',
        http_port:    4567,
        plugins:      [Factoids,
                       Sed,
                       Tweet,
                       Github,
                       PingLists,
                       Youtube,
                       Cinch::HttpServer]
    })

Signal.trap('TERM') do
  $bot.quit
end
Signal.trap('HUP') do
  $bot.reload_conf
end

$bot.start