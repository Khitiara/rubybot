require 'rubybot/plugins/factoids/macro_semantic_error'
require 'rubybot/plugins/factoids/macro'

module Rubybot
  module Plugins
    class Factoids
      class Macros
        def self.macro_regex
          /\$\{(?<name>[a-zA-Z_]+)(\((?<args>.*)\))?}/
        end

        class << self
          attr_accessor :macros
        end

        self.macros = {
          'urlencode' => Macro.implement do |_, _, _, args, _|
            unless args.length == 1
              fail MacroSemanticError, 'Urlencode macro takes exactly one argument!'
            end
            CGI.escape args[0]
          end,
          'list'      => Macro.implement do |_, _, _, args, _|
            unless args.length == 0
              fail MacroSemanticError, 'List macro takes no arguments!'
            end
            factoids.keys.join(', ')
          end,
          'wget'      => Macro.implement do |_, _, _, args, _|
            unless args.length == 2
              fail MacroSemanticError, 'Wget macro takes exactly two arguments!'
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
              fail MacroSemanticError, 'Arg macro takes at least one argument!'
            end
            name = args.shift
            Macros.process(resp(name), nick, args.join(' ').scan(arg_regex).map { |it| it[0] })
          end,
          'selrand'   => Macro.implement do |_, _, _, args, _|
            unless args.length >= 1
              fail MacroSemanticError, 'selrand macro takes at least one argument!'
            end
            args[rand(args.length)]
          end,
          'echo'      => Macro.implement do |_, _, args, _, _|
            args
          end,
          'roll'      => Macro.implement do |_, _, args, _, nick|
            blob      = /(?:(?:(?'times'\d+)#)?(?'num'\d+))?d(?'sides'\d+)(?:(?'mod'[+-])(?'modnum'\d+))?/.match args
            repeats   = blob['times'].to_i || 1
            rolls     = blob['num'].to_i || 1
            sides     = blob['sides'].to_i
            offset_op = blob['mod']
            offset    = blob['modnum']
            repeats   = 1 if repeats < 1
            rolls     = 1 if rolls < 1
            total     = 0
            repeats.times do
              rolls.times do
                total += rand(sides.to_i) + 1
              end
              total = total.send(offset_op, offset.to_i) if offset_op
            end

            "#{nick}: You rolled #{args} -> #{total}"
          end
        }

        # noinspection RubyResolve
        def self.process(m, resp, nick, args, rest)
          resp = resp.gsub(/%ioru%/) { |_| args[0] || nick }
          resp = resp.gsub(/%me%/, nick)
          resp = resp.gsub(/%a(\d+)%/) do |_|
            args[Integer(Regexp.last_match(1))]
          end
          resp = resp.gsub(/!!/, rest)
          resp.gsub macro_regex do |_|
            String name = $LAST_MATCH_INFO['name']
            macro_args_s = process(m, $LAST_MATCH_INFO['args'] || '', nick, args, rest)
            Array macro_args = macro_args_s.scan(arg_regex).map { |it| it[0] } || []
            macro = macros[name]
            macro.run(m, args, macro_args_s, macro_args, nick)
          end
        end

        def self.register(clazz, name = nil)
          macros[name || clazz.name.downcase] = clazz.new
        end

        def self.macro_alias(n, a)
          macros[a] = macros[n]
        end

        def self.arg_regex
          Rubybot::Plugins::Factoids.arg_regex
        end
      end
    end
  end
end
