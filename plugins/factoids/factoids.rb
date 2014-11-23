require 'json'
require_relative 'macro_semantic_error'

$factoid_filename = 'factoids.json'

file = File.read($factoid_filename).force_encoding('UTF-8')
$factoid_parse = JSON.parse(file)
$reserved = $factoid_parse['reserved']
$user = $factoid_parse['user']

def factoids
  $user.merge $reserved
end

def save
  data = {
      reserved: $reserved,
      user: $user
  }
  text = JSON.pretty_unparse data
  File.open($factoid_filename, 'w') do |file|
    file.puts text
  end
end

$arg_regex = /([^\s'"]*(?:"[^"]*"|'[^']*'|[^"'\s]+)[^\s'"]*)/

module Macros
  @@macro_regex = /\$\{(?<name>[a-zA-Z_]+)(\((?<args>.*)\))?}/

  # noinspection RubyAssignmentExpressionInConditionalInspection
  @@macros = {
      urlencode: lambda do |_, args, _|
        unless args.length == 1
          raise MacroSemanticError.new('Urlencode macro takes exactly one argument!')
        end
        CGI::escape args[0]
      end,
      list: lambda do |_, args, _|
        unless args.length == 0
          raise MacroSemanticError.new('List macro takes no arguments!')
        end
        factoids.keys.join(', ')
      end,
      wget: lambda do |_, args, _|
        unless args.length == 2
          raise MacroSemanticError.new('Wget macro takes exactly two arguments!')
        end
        require 'net/http'
        line_delim_extractor = /lines:'(?<delim>[^']+)'/

        url = args[1]
        res_format = args[0]

        res = Net::HTTP.get_response(URI(url))
        body = res.body
        if lines = line_delim_extractor.match(res_format)
          delim = lines['delim']
          body.split(/\n/).join(delim)
        else
          body
        end
      end,
      call: lambda do |_, args, nick|
        unless args.length >= 1
          raise MacroSemanticError.new('Arg macro takes at least one argument!')
        end
        name = args.shift
        Macros::process(factoids[name], nick, args.join(' ').scan($arg_regex).map {|it| it[0]})
      end,
      selrand: lambda do |_, args, _|
        unless args.length >= 1
          raise MacroSemanticError.new('selrand macro takes at least one argument!')
        end
        args[rand(args.length)]
      end
  }

  def process(resp, nick, args)
    resp = resp.gsub /%ioru%/ do |_|
      args[0] || nick
    end
    resp = resp.gsub /%me%/ do |_|
      nick
    end
    resp = resp.gsub /%a(\d+)%/ do |_|
      args[$1]
    end
    resp.gsub @@macro_regex do |_|
          String name = $~['name']
          macro_args_s = process($~['args'] || '', nick, args)
          Array macro_args = macro_args_s.scan($arg_regex).map {|it| it[0]} || []
          macro = @@macros[name.to_sym]
          macro.call(args, macro_args, nick)
        end
  end

  module_function :process
end

class Factoids
  include Cinch::Plugin

  set(:prefix => '.')

  match /([a-zA-Z]+)(.*)/
  match /\+([a-zA-Z]+).*/, method: :show
  match /\*([a-zA-Z]+)(?: (.+))?/, method: :set

  def set(msg, name, value = nil)
    if $reserved.has_key? name
      msg.reply "#{msg.user.nick}: #{name} is reserved!"
    else
      if value.nil?
        $user.delete name
      else
        $user[name] = value
      end
      debug factoids.inspect
      save
    end
  end

  def show(msg, name)
    if factoids.has_key?(name)
      msg.reply factoids[name]
    end
  end

  def execute(msg, command, args)
    if factoids.has_key?(command)
      begin
        resp = Macros::process(factoids[command], msg.user.nick, args.scan($arg_regex).map {|it| it[0]}) || ''

        if resp.start_with?('/me ')
          msg.action_reply resp[4..-1]
        else
          msg.reply resp
        end
      rescue MacroSemanticError => e
        msg.reply "#{msg.user}: Macro Semantics Error: #{e.msg}"
      rescue Exception => e
        msg.reply e.message
        debug "#{e.message}\n#{e.backtrace.join('\n')}"
      end
    end
  end
end