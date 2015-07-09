require 'rubybot/core/acl'
require 'rubybot/plugins/http_server'
require 'timers'
require 'active_support/time'
require 'active_support/inflector'
require 'cinch'
require 'yajl'
require 'revolver'
require 'pry'

module Rubybot
  class Bot < Cinch::Bot
    attr_reader :bot_config
    attr_reader :owner
    attr_reader :acl

    def initialize(data = {})
      super()
      @cfg_filename = data[:cfg_filename]
      reload_conf
      @timers = Timers::Group.new
      @logs = {}
      @fix_nick = @timers.every(1.hours) do
        @nick = @bot_config[:bot][:nick]
      end

      on :disconnected do
        @fix_nick.cancel
      end
    end

    def logs(channel)
      @logs[channel] ||= Revolver.new 500
    end

    def save
      File.write @cfg_filename, JSON.pretty_generate(@bot_config)
      reload_conf
    end

    def reload_conf
      @cfg_file   = File.read @cfg_filename
      @bot_config = Yajl::Parser.parse @cfg_file, symbolize_names: true
      @owner      = @bot_config[:owner]
      @acl        = Rubybot::Core::Acl.new(self)

      # load plugins
      @bot_config[:bot][:plugins][:plugins].each { |clazz| require ActiveSupport::Inflector.underscore clazz }
      @bot_config[:bot][:plugins][:options] =
        Hash[@bot_config[:bot][:plugins][:options].map { |k, v| [ActiveSupport::Inflector.constantize(k.to_s), v] }]
      config.load @bot_config[:bot]
    end
  end
end
