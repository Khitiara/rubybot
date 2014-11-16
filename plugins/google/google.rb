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
      node.replace Format(:italic, content)
    when 'b'
      node.replace Format(:bold, content)
    else
      # type code here
  end
  Sanitize.node!(node, elements: %w(b i))
end

class Google
  include Cinch::Plugin
  set(:prefix => '?')
  match /g (.+)/, method: :search

  def search(m, query)
    GoogleAjax.referrer = 'cadwallion.com'
    result = GoogleAjax::Search.web(query)[:results][0]
    title = result[:title]
    title = Sanitize.fragment(title, :transformers => [$formatter])
    m.reply "Result: #{title} - #{result[:url]}"
  end
end
