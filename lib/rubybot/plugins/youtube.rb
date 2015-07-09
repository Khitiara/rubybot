require 'chronic_duration'
require 'open-uri'
require 'json'
require 'iso8601'
require 'rubybot/core/command_info'

module Rubybot
  module Plugins
    class Youtube
      include Cinch::Plugin
      YT_REGEX = %r{.*https?://(?:www\.)?youtube.com/watch\?(?=.*v=(?<id>\w+))(?:\S*).*}
      set plugin_name: 'youtube'
      match YT_REGEX, use_prefix: false

      def execute(m, id)
        hash  = JSON.parse(open(url id, config['yt_key']).read)['items'][0]
        title = hash['snippet']['title']
        dur   = format_duration hash['contentDetails']['duration']
        likes = hash['statistics']['likeCount']
        dislikes = hash['statistics']['dislikeCount']
        m.reply "Youtube: #{title} (#{dur}), #{likes} likes, #{dislikes} dislikes"
      end

      def commands
        [Rubybot::Core::CommandInfo.new('<youtube video url>',
                                        'Prints information about the given Youtube video',
                                        prefix: false)]
      end

      private

      def url(id, key)
        "https://www.googleapis.com/youtube/v3/videos?id=#{id}&part=snippet%2CcontentDetails%2Cstatistics&key=#{key}"
      end

      def format_duration(raw)
        ChronicDuration.output(ISO8601::Duration.new(raw).to_seconds, keep_zero: true)
      end
    end
  end
end
