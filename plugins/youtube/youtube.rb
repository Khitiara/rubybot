require 'video_info'
require 'chronic_duration'
class Youtube
  include Cinch::Plugin
  YT_REGEX = /.*(https?:\/\/(?:www\.)?youtube.com\/watch\?(?=.*v=\w+)(?:\S+)?).*/
  match YT_REGEX, use_prefix: false

  def execute(m, link)
    vid   = VideoInfo.new(link)
    title = vid.title
    dur   = ChronicDuration.output(vid.duration, :keep_zero => true)
    m.reply "Youtube: #{title} (#{dur})"
  end
end