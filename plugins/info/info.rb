require 'json'
require 'net/http'
file = File.read('responses.json')
$responses = JSON.parse(file)
$wgetRegex = /\$\{wget (?<format>(lines\:\'[^']+\')|static) (?<url>[^ ]+)\}/
$lineDelimExtractor = /lines\:\'(?<delim>[^']+)\'/
$argRegex = /\{(?<num>[0-9]+)\}/
class Info
  include Cinch::Plugin
  set(:prefix => '.')
  match /([a-zA-Z]+)(.*)/
  def execute(msg, command, args)
    if not $responses.has_key?(command)
      m.reply "Invalid command: #{command}"
    else
      resp = $responses[command]
      resp.gsub! /\$\{list\}/, $responses.keys.join(', ')
      resp.gsub!($wgetRegex) do |match|
        m = $wgetRegex.match(resp)
        url = m['url']
        resFormat = m['format']
        res = Net::HTTP.get_response(URI(url))
        body = res.body
        puts body
        if lines = $lineDelimExtractor.match(resFormat)
          delim = lines['delim']
          body.split(/\n/).join(delim)
        else
          body
        end
      end
      realArgs = args.strip.split(' ')
      resp.gsub!($argRegex) {|match|
        return realArgs[Integer(match['num'])]
      }
      puts resp
      if resp.start_with?('\/me ')
        msg.action_reply resp[4..-1]
      else
        msg.reply resp
      end
    end
  end
end
