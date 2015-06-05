require File.dirname(__FILE__) + '/acl'
require File.dirname(__FILE__) + '/LogDB'
require File.dirname(__FILE__) + '/bot_admin'
require 'timers'
require 'active_support/time'
require 'cinch'
require 'yajl'

module ElrosBot
  class Bot < Cinch::Bot
    attr_accessor :bot_config
    attr_reader :owner
    attr_reader :acl
    attr_accessor :logs

    def initialize(data)
      super() do
        @cfg_filename = data[:cfg_filename]
        @cfg_file   = File.read @cfg_filename
        @bot_config = Yajl::Parser.parse(@cfg_file)
        @owner      = @bot_config['owner']
        @acl        = ElrosBot::Acl.new(self)
        @timers     = Timers::Group.new
        @logs = Log_DB.new
        @fix_nick   = @timers.every(1.hours) do
          @nick = @bot_config['bot']['nick']
        end
        configure do |c|
          @bot_config['bot'].each do |k, v|
            segments = k.split('.')
            object   = c
            segments.each do |s|
              # call the setter for the last segment on the previous segment's object
              # or the main config object if there was only one segment
              if s == segments.last
                object.send s + '=', v
                # for all segments but the last, call the getter and obtain a nested config object
              else
                object = c.send s
              end
            end
          end
          # noinspection RubyResolve
          c.plugins.plugins = data[:plugins] + [BotAdmin]

          c.plugins.options[Cinch::HttpServer] = {
              host: data[:http_host],
              port: data[:http_port]
          }
        end

        on :disconnected do
          @fix_nick.cancel
        end
      end
      yield self if block_given?
    end

    def save
      text = JSON.pretty_unparse @bot_config
      File.open(@cfg_filename, 'w') do |file|
        file.puts text
      end
      reload_conf
    end

    def reload_conf
      @cfg_file   = File.read @cfg_filename
      @bot_config = Yajl::Parser.parse(@cfg_file)
      @owner      = @bot_config['owner']
      @acl        = ElrosBot::Acl.new(self)
      configure do |c|
        @bot_config['bot'].each do |k, v|
          segments = k.split('.')
          object   = c
          segments.each do |s|
            # call the setter for the last segment on the previous segment's object
            # or the main config object if there was only one segment
            if s == segments.last
              object.send s + '=', v
              # for all segments but the last, call the getter and obtain a nested config object
            else
              object = c.send s
            end
          end
        end
      end
    end
  end
end