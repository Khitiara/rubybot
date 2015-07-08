require 'rubybot/core/acl'
require 'rubybot/core/log_db'
require 'rubybot/plugins/http_server/http_server'
require 'timers'
require 'active_support/time'
require 'cinch'
require 'yajl'

module Rubybot
  class Bot < Cinch::Bot
    attr_accessor :bot_config
    attr_reader :owner
    attr_reader :acl
    attr_accessor :logs

    def initialize(data = {})
      super() do
        @cfg_filename = data[:cfg_filename]
        reload_conf
        @timers = Timers::Group.new
        @logs = Core::LogDb.new
        @fix_nick = @timers.every(1.hours) do
          @nick = @bot_config['bot']['nick']
        end
        configure do |c|
          # noinspection RubyResolve
          c.plugins.plugins = data[:plugins]

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
      File.write @cfg_filename, JSON.pretty_generate(@bot_config)
      reload_conf
    end

    def reload_conf
      @cfg_file   = File.read @cfg_filename
      @bot_config = Yajl::Parser.parse(@cfg_file)
      @owner      = @bot_config['owner']
      @acl        = Rubybot::Core::Acl.new(self)
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
