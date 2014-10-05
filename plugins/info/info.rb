require 'json'
class Info
  include Cinch::Plugin
  prefix '.'
  match /([a-zA-Z]+)(.*)/
  file = File.read('responses.json')
  responses = JSON.parse(file)
  def execute(m, command, args)
    if not responses.has_key?(command) then
      m.reply "Invalid command: #{command}"
    else
      resp = responses[command]
      resp.gsub /\$\{list\}/, responses.keys.join ', '
    end
  end
end
