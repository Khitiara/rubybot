require 'googleajax'
require 'sanitize'
require File.dirname(__FILE__) + '/../factoids/factoids'
require File.dirname(__FILE__) + '/../factoids/macro'

class Google < Macro
  # noinspection RubyResolve
  def run(_, _, args, _, _)
    GoogleAjax.referrer = 'robotbrain.info'
    result              = GoogleAjax::Search.web(args)[:results][0]
    title               = result[:title]
    title               = Sanitize.fragment(title)
    "Result: #{title} - #{result[:url]}"
  end
end
Macros.register Google
