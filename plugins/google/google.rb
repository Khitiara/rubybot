require 'googleajax'
require 'sanitize'
require 'cinch/formatting'

$bold_regex = /<b(\b.*)?>(?<bold>.*)<\/b>/
$italics_regex = /<i(\b.*)?>(?<italic>.*)<\/i>/
$formatter = lambda do |env|
  node = env[:node]
  content = node.content
  case env[:node_name]
    when 'i'
      out = Format(:italic, content)
    when 'b'
      out = Format(:bold, content)
    else
      out = content
  end
  node.replace out
end

class Google
  include Cinch::Plugin
  set(:prefix => '?')
  match /g (.+)/, method: :search

  def search(m, query)
    GoogleAjax.referrer = 'cadwallion.com'
    result = GoogleAjax::Search.web(query)[:results][0]
    title = result[:title]
    title = Sanitize.fragment(title, :elements => %w(b i), :transformers => [$formatter])
    m.reply "Result: #{title} - #{result[:url]}"
  end
end
