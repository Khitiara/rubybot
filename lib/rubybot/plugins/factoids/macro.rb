module Rubybot
  module Plugins
    module Factoids
      class Macro
        def run(_,_, _, _, _)
          raise 'SubclassResponsibility'
        end

        def self.implement (&blk)
          (Class.new Macro do
            def initialize(blk)
              @blk = blk
            end

            def run(m, a, b, c, d)
              @blk.call(m, a, b, c, d)
            end
          end).new(blk)
        end
      end
    end
  end
end