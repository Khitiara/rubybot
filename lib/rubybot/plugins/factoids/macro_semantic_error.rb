module Rubybot
  module Plugins
    module Factoids
      class MacroSemanticError < Exception
        attr_accessor :msg

        def initialize(msg = '')
          @msg = msg
        end
      end
    end
  end
end