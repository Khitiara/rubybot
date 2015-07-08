require 'revolver'

module Rubybot
  module Core
    class LogDb
      def initialize
        @channels = Hash.new
        @queries = Hash.new
      end

      def channel(name)
        @channels[name] ||= Revolver.new 500
      end

      def user(name)
        @queries[name] ||= Revolver.new 500
      end
    end
  end
end
