require 'rspec/collection_matchers'
require 'cinch/test'

def get_plugin_configuration(clazz)
  conf = JSON.parse File.read('config.json'), symbolize_names: true
  conf[:bot][:plugins][:options][clazz.to_s.to_sym]
end

module Cinch
  class LoggerList
    def each
    end
  end
end
