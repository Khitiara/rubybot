require 'json'
require File.dirname(__FILE__) + '/macro_semantic_error'
require File.dirname(__FILE__) + '/macro'
require 'cgi'
require 'active_support/core_ext/class/attribute_accessors'

$factoid_filename = 'factoids.json'

file           = File.read($factoid_filename).force_encoding('UTF-8')
$factoid_parse = JSON.parse(file)
$reserved      = $factoid_parse['reserved']
$user          = $factoid_parse['user']

def factoids
  $user.merge $reserved
end

def resp(name, args=[])
  if Macros.macros.key? name
    "${#{name}#{args.empty? ? '' : "(#{args.join ' '})"}}"
  elsif factoids.key? name
    factoids[name]
  end
end

def save
  data = {
      reserved: $reserved,
      user:     $user
  }
  text = JSON.pretty_unparse data
  File.open($factoid_filename, 'w') do |file|
    file.puts text
  end
end

$arg_regex = /([^\s'"]*(?:"[^"]*"|'[^']*'|[^"'\s]+)[^\s'"]*)/

module Macros
  module_function

  mattr_accessor :macro_regex, :macros
  @@macro_regex = /\$\{(?<name>[a-zA-Z_]+)(\((?<args>.*)\))?}/

  @@macros = {
      'urlencode' => Macro.implement do |_, _, _, args, _|
        unless args.length == 1
          raise MacroSemanticError.new('Urlencode macro takes exactly one argument!')
        end
        CGI::escape args[0]
      end,
      'list'      => Macro.implement do |_, _, _, args, _|
        unless args.length == 0
          raise MacroSemanticError.new('List macro takes no arguments!')
        end
        factoids.keys.join(', ')
      end,
      'wget'      => Macro.implement do |_, _, _, args, _|
        unless args.length == 2
          raise MacroSemanticError.new('Wget macro takes exactly two arguments!')
        end
        require 'net/http'
        line_delim_extractor = /lines:'(?<delim>[^']+)'/

        url        = args[1]
        res_format = args[0]

        res  = Net::HTTP.get_response(URI(url))
        body = res.body
        if (lines = line_delim_extractor.match(res_format))
          delim = lines['delim']
          body.split(/\n/).join(delim)
        else
          body
        end
      end,
      'call'      => Macro.implement do |_, _, _, args, nick|
        unless args.length >= 1
          raise MacroSemanticError.new('Arg macro takes at least one argument!')
        end
        name = args.shift
        Macros::process(resp(name), nick, args.join(' ').scan($arg_regex).map { |it| it[0] })
      end,
      'selrand'   => Macro.implement do |_, _, _, args, _|
        unless args.length >= 1
          raise MacroSemanticError.new('selrand macro takes at least one argument!')
        end
        args[rand(args.length)]
      end,
      'echo'      => Macro.implement do |_, _, args, _, _|
        args
      end
  }

  # noinspection RubyResolve
  def process(m, resp, nick, args, rest)
    resp = resp.gsub /%ioru%/ do |_|
      args[0] || nick
    end
    resp = resp.gsub /%me%/ do |_|
      nick
    end
    resp = resp.gsub /%a(\d+)%/ do |_|
      args[Integer($1)]
    end
    resp = resp.gsub /!!/ do |_|
      rest
    end
    resp.gsub macro_regex do |_|
      String name = $~['name']
      macro_args_s = process(m, $~['args'] || '', nick, args, rest)
      Array macro_args = macro_args_s.scan($arg_regex).map { |it| it[0] } || []
      macro = macros[name]
      macro.run(m, args, macro_args_s, macro_args, nick)
    end
  end

  def register(clazz)
    @@macros[clazz.name.downcase] = clazz.new
  end

  def macro_alias(n, a)
    @@macros[a] = @@macros[n]
  end
end

$factoid_command = /([a-zA-Z]+)([^>]*)(?:\s*>\s*((?:[a-zA-Z]+)(?:[^>]*)))?/

class Factoids
  include ElrosBot::Plugin
  include Cinch::Plugin

  set(:prefix => '?')
  match $factoid_command
  match /\+([a-zA-Z]+).*/, method: :show
  match /\*([a-zA-Z]+)(?: (.+))?/, method: :set

  def set(msg, name, value = nil)
    if $reserved.key? name or Macros.macros.key? name
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
    if factoids.key?(name)
      msg.reply factoids[name]
    elsif Macros.macros.key? name
      msg.reply Macros.macros[name].name || 'Macro'
    end
  end

  def execute(msg, command, args, rest)
    res = process(msg, '', command, args, rest)
    if res.start_with? '/me '
      msg.action_reply res[4..-1]
    else
      msg.reply res
    end
  end

  def process(msg, prev, command, args, rest)
    if prev.nil? and msg.channel
      prev = bot.logs.channel(msg.channel.name).to_a.reverse.first || ''
    end
    args_s = args.strip
    args   = args_s.split
    if Macros.macros.key? command
      resp = "${#{command}#{args_s.nil? ? '' : "(#{args_s})"}}"
    else
      resp = factoids[command]
    end
    res = Macros.process msg, resp, msg.user.nick, args, prev
    if not rest.nil?
      match = $factoid_command.match(rest).to_a.drop 1
      blob  = process msg, res, *match
    else
      blob = res
    end
    blob
  end
end