require 'googleajax'
class Google
  include Cinch::Plugin
  prefix '?'
  match /g (.+)/, method: :search
  def search(m, query)
    GoogleAjax.referrer = 'cadwallion.com'
    result = GoogleAjax::Search.web(query)[:results][0]
    m.reply "Result: #{result[:title]} - #{result[:url]}"
  end
end