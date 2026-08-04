require 'drasil'
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  # Include helpers
  config.include ClientHelper
  config.include StubHelper

  # Drasil::Config is a global singleton and Drasil::Base holds process-wide
  # state, so each example starts from a clean slate.
  config.after do
    Drasil::Config.reset!
    Drasil::Base.include_root_in_json false
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.formatter = :documentation
end
