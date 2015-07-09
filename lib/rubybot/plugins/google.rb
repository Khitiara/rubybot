require 'googleajax'
require 'sanitize'
require 'rubybot/plugins/factoids/macros'
require 'rubybot/plugins/factoids/macro'

module Rubybot
  module Plugins
    class Google # < Factoids::Macro
      include Cinch::Plugin

      def initialize(bot)
        super
        GoogleAjax.referrer = 'robotbrain.info'
        Factoids::Macros.register GoogleMacro, 'google'
        Factoids::Macros.macro_alias 'google', 'g'
      end

      class GoogleMacro < Factoids::Macro
        # noinspection RubyResolve
        def run(_, _, args, _, _)
          result = GoogleAjax::Search.web(args)[:results][0]
          title = result[:title]
          title = Sanitize.fragment(title)
          "Result: #{title} - #{result[:url]}"
        end
      end
    end
  end
end
