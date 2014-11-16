require 'googleajax'
require 'sanitize'
require 'cinch/formatting'

$bold_regex = /<b(\b.*)?>(?<bold>.*)<\/b>/
$italics_regex = /<i(\b.*)?>(?<italic>.*)<\/i>/

class Google
  include Cinch::Plugin
  set(:prefix => '?')
  match /g (.+)/, method: :search

  def search(m, query)
    GoogleAjax.referrer = 'cadwallion.com'
    result = GoogleAjax::Search.web(query)[:results][0]
    title = result[:title]
    title = Sanitize.fragment(title, :elements => %w(b i))
    title.gsub!($bold_regex) do |_|
      m = $bold_regex.match(title)
      Format(:bold, m['bold'])
    end
    title.gsub!($italics_regex) do |_|
      m = $italics_regex.match(title)
      Format(:italic, m['italic'])
    end
    m.reply "Result: #{title} - #{result[:url]}"
  end
end
