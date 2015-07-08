require 'googleajax'
require 'sanitize'
require 'rubybot/plugins/factoids/macros'
require 'rubybot/plugins/factoids/macro'

module Rubybot
  module Plugins
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
  end
end
Macros.register Rubybot::Plugins::Google
Macros.macro_alias 'google', 'g'
