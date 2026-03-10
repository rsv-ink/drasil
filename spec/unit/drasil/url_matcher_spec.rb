# frozen_string_literal: true

RSpec.describe Drasil::UrlMatcher do
  describe "#match?" do
    context "when url matches the pattern" do
      it "returns true" do
        url = "https://example.com/random-sellers/582381cc-7892-478c-a381-08d02375563e/balances/?query=John"
        url_pattern = "/random-sellers/:id/"
        url_matcher = Drasil::UrlMatcher.new(url, url_pattern)

        expect(url_matcher.match?).to be_truthy
      end
    end

    context "when url doesn't match the pattern" do
      it "returns false" do
        url = "https://example.com/orders"
        url_pattern = "/random-sellers/:id/"
        url_matcher = Drasil::UrlMatcher.new(url, url_pattern)

        expect(url_matcher.match?).to be_falsey
      end
    end

    context "when url pattern is nil" do
      it "returns false" do
        url = "https://example.com/orders"
        url_pattern = nil
        url_matcher = Drasil::UrlMatcher.new(url, url_pattern)

        expect(url_matcher.match?).to be_falsey
      end
    end

    context "when url pattern is invalid" do
      it "returns false" do
        url = "https://example.com/orders"
        url_pattern = "?["
        url_matcher = Drasil::UrlMatcher.new(url, url_pattern)

        expect(url_matcher.match?).to be_falsey
      end
    end
  end
end
