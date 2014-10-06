require 'revolver'
class Log_DB
  def initialize
    @channels = Hash.new
    @queries = Hash.new
  end
  def channel(name)
    @channels[name] = Revolver.new(500) unless @channels.has_key?(name)
    @channels[name]
  end

  def user(name)
    @queries[name] = Revolver.new(500) unless @queries.has_key?(name)
    @queries[name]
  end
end