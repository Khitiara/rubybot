require 'twitter'

$twitter = Twitter::REST::Client.new do |config|
  config.consumer_key = $config['twitter']['consumer_key']
  config.consumer_secret = $config['twitter']['consumer_secret']
  config.access_token = $config['twitter']['access_key']
  config.access_token_secret = $config['twitter']['access_secret']
end

class Tweet
  include Cinch::Plugin

  match /.*(https:\/\/twitter.com\/[^\/]+\/status\/[^\/]+)/, :use_prefix => false

  def execute(m, uri)
    status = $twitter.status(URI(uri))
    text = status.full_text
    user = status.user.screen_name
    m.reply "@#{user}: #{text}"
  end
end