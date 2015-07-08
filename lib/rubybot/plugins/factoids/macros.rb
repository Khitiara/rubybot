require 'rubybot/plugins/factoids/macro_semantic_error'
require 'rubybot/plugins/factoids/macro'

module Rubybot
  module Plugins
    module Factoids
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
                if offset_op
                  total = total.send(offset_op, offset.to_i)
                end
              end

              "#{nick}: You rolled #{args} -> #{total}"
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
    end
  end
end
