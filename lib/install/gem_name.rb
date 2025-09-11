require "drasil"

Drasil.configure do |config|
  # General
  config.base_url             = <API_BASE_URL>
  config.include_root_in_json = false

  # Pagination
  #
  # example: /resources?page=1&limit=10
  config.page_query_name      = :page
  config.per_page_query_name  = :limit

  # Authentication
  #
  # config.headers = {
  #   "Authorization": "Basic <API_SECRET_KEY>"
  # }

  # Parsers
  # config.add_parser "/resources/:id", ExampleApi::Parsers::DefaultParser
end
