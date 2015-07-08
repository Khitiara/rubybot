require 'rubybot/plugins/factoids/macros'
require 'json'

module Rubybot
  module Plugins
    module Factoids
      class Storage
        def initialize
          @factoid_filename = 'factoids.json'
          read
        end

        attr_reader :reserved, :user
        
        def factoids
          @user.merge @reserved
        end

        def resp(name, args = [])
          if Macros.macros.key? name
            "${#{name}#{args.empty? ? '' : "(#{args.join ' '})"}}"
          elsif factoids.key? name
            factoids[name]
          end
        end

        def reserve_factoid(name)
          @reserved[name] = @user.delete name
        end

        def free_factoid(name)
          @user[name] = @reserved.delete name
        end

        def save
          data = {
              reserved: @reserved,
              user:     @user
          }
          File.write @factoid_filename, JSON.pretty_unparse data
        end
        
        def read
          parsed = JSON.parse File.read @factoid_filename
          @reserved = parsed['reserved']
          @user = parsed['user']
        end
      end
    end
  end
end