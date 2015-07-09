module Rubybot
  module Core
    class CommandInfo
      attr_reader :command
      attr_reader :with_prefix
      attr_reader :help_short
      attr_reader :help_long

      def initialize(command, help_short, options = {})
        @command = command
        @help_short = help_short
        @help_long = options[:help_long] || @help_short
        @with_prefix = options.key? :prefix ? options[:prefix] : true
      end
    end
  end
end
