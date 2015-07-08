require 'chronic_duration'

require 'open-uri'
require 'json'
require 'iso8601'

module Rubybot
  module Plugins
    class Youtube
      include Cinch::Plugin
      YT_REGEX = /.*https?:\/\/(?:www\.)?youtube.com\/watch\?(?=.*v=(?<id>\w+))(?:\S+)?.*/
      match YT_REGEX, use_prefix: false

      def execute(m, id)
        video = "https://www.googleapis.com/youtube/v3/videos?id=#{id}&part=snippet%2CcontentDetails%2Cstatistics&key=#{bot.bot_config['yt_key']}"
        hash = JSON.parse(open(video).read)['items'][0]
        title = hash['snippet']['title']
        dur   = ChronicDuration.output(ISO8601::Duration.new(hash['contentDetails']['duration']).to_seconds, :keep_zero => true)
        likes = hash['statistics']['likeCount']
        dislikes = hash['statistics']['dislikeCount']
        m.reply "Youtube: #{title} (#{dur}), #{likes} likes, #{dislikes} dislikes"
      end
    end
  end
end