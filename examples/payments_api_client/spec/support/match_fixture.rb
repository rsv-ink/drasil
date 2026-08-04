RSpec::Matchers.define :match_fixture do |fixture_path|
  match do |actual|
    actual == JSON.parse(fixture(fixture_path))
  end

  failure_message do |actual|
    "expected that #{actual} would match #{fixture(fixture_path)}"
  end
end
