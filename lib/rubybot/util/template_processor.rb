module Rubybot
  module Util
    class TemplateProcessor
      def initialize(variables)
        fail :InvalidArgumentsError, 'TemplateProcess.new must be called with hash as argument' unless variables.is_a? Hash
        @variables = variables
      end

      def process(data)
        @variables.each do |key, value|
          data = data.gsub "$#{key.to_s.upcase}", value unless key.nil? || value.nil?
        end
        data
      end

      def self.process_file(variables, files = {})
        processor = TemplateProcessor.new variables
        files.each do |input, output|
          File.write input, processor.process(File.read output)
        end
      end
    end
  end
end
