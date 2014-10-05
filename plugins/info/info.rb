require 'json'
require 'net/http'
class Info
  include Cinch::Plugin
  set(:prefix => '.')
  match /([a-zA-Z]+)(.*)/
  file = File.read('responses.json')
  responses = JSON.parse(file)
  wgetRegex = /\$\{wget (?<format>(lines\:\'[^']+\')|static) (?<url>[^ ]+)\}/
  lineDelimExtractor = /lines\:\'(?<delim>[^']+)\'/
  argRegex = /\{(?<num>[0-9]+)\}/
  def execute(m, command, args)
    puts command
    if not @responses.has_key?(command)
      m.reply "Invalid command: #{command}"
    else
      resp = @responses[command]
      resp.gsub! /\$\{list\}/, responses.keys.join(', ')
      resp.gsub!(@wgetRegex) {|match|
        url = match['url']
        resFormat = match['format']
        http.request_get url {|res|
          body = res.body
          if lines = @lineDelimExtractor.match(resFormat)
            delim = lines['delim']
            result = body.split(/\n/).join delim
          else
            result = body
          end
        }
        return result
      }
      realArgs = args.strip.split(' ')
      resp.gsub!(@argRegex) {|match|
        return realArgs[Integer(match['num'])]
      }
      puts resp
      if resp.starts_with?('\/me ')
        m.action_reply resp[4..-1]
      else
        m.reply resp
      end
    end
  end
end
