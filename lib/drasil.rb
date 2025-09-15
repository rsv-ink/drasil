# frozen_string_literal: true

require_relative "drasil/version"

require "spyke"
require "multi_json"

require "drasil/config"
require "drasil/error"
require "drasil/response/raise_error"
require "drasil/json_parser"
require "drasil/url_matcher"
require "drasil/url_pattern"
require "drasil/parser"
require "drasil/railtie" if defined?(Rails)

module Drasil
  class Error < StandardError; end

  class << self
    def configure
      yield(Config)

      raise Error.new("No parsers have been registered.") if Config.parsers.blank?

      Spyke::Base.connection = Faraday.new(url: Config.base_url) do |conn|
        conn.headers = Config.headers

        conn.request   :multipart
        conn.request   :json

        conn.adapter   Faraday.default_adapter

        conn.use JSONParser
        conn.use Drasil::Response::RaiseError

        Config.middlewares.each do |middleware|
          conn.use middleware
        end
      end
    end
  end
end

require "drasil/base"
