require 'googleajax'
require 'sanitize'

class Google
  include Cinch::Plugin
  set(:prefix => '?')
  match /g (.+)/, method: :search

  def search(m, query)
    GoogleAjax.referrer = 'cadwallion.com'
    result = GoogleAjax::Search.web(query)[:results][0]
    title = result[:title]
    title = Sanitize.fragment(title)
    m.reply "Result: #{title} - #{result[:url]}"
  end
end
