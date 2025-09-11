require "webmock/rspec"
require "support/mock_helper"
require "support/match_fixture"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.formatter = :documentation

  config.include MockHelper

end

WebMock.disable_net_connect!(allow_localhost: true)
