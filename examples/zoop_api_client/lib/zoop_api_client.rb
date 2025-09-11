# frozen_string_literal: true

require_relative "zoop_api_client/version"

require "drasil"

require "zoop_api_client/parsers/default_parser"
require "zoop_api_client/resources/seller"

Drasil.configure do |config|
  config.base_url             = "your_base_url_here"
  config.include_root_in_json = false

  config.page_query_name      = :page
  config.per_page_query_name  = :limit

  config.headers = {
    "Authorization": "your_secret_key_here"
  }

  config.add_parser "/sellers/:id", ZoopApiClient::Parsers::DefaultParser
end
