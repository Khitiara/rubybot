require 'googleajax'
require 'sanitize'
require 'cinch/formatting'

$bold_regex = /<b>(.*)<\/b>/
$italics_regex = /<i>(.*)<\/i>/

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
      Format(:bold, $1)
    end
    title.gsub!($italics_regex) do |_|
      Format(:italic, $1)
    end
    m.reply "Result: #{title} - #{result[:url]}"
  end
end
