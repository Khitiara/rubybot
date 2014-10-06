require 'json'
require 'net/http'
file = File.read('responses.json')
$responses = JSON.parse(file)
$wget_regex = /\$\{wget (?<format>(lines:'[^']+')|static) (?<url>[^ ]+)\}/
$line_delim_extractor = /lines:'(?<delim>[^']+)'/
$arg_regex = /\{(?<num>[0-9]+)\}/
class Info
  include Cinch::Plugin
  set(:prefix => '.')
  match /([a-zA-Z]+)(.*)/
  def execute(msg, command, args)
    if $responses.has_key?(command)
      resp = $responses[command]
      resp.gsub! /\$\{list\}/, $responses.keys.join(', ')
      resp.gsub!($wget_regex) do |match|
        m = $wget_regex.match(resp)
        url = m['url']
        res_format = m['format']
        res = Net::HTTP.get_response(URI(url))
        body = res.body
        if lines = $line_delim_extractor.match(res_format)
          delim = lines['delim']
          body.split(/\n/).join(delim)
        else
          body
        end
      end
      real_args = args.strip.split(' ')
      resp.gsub!($arg_regex) { |match|
        return real_args[Integer(match['num'])]
      }
      if resp.start_with?('\/me ')
        msg.action_reply resp[4..-1]
      else
        msg.reply resp
      end
    else
      msg.reply "Invalid command: #{command}"
    end
  end
end
