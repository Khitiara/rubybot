module Rubybot
  module Plugins
    class Factoids
      class MacroSemanticError < Exception
        attr_accessor :msg

        def initialize(msg = '')
          @msg = msg
        end
      end
    end
  end
end
