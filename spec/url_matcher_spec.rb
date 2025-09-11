# frozen_string_literal: true

RSpec.describe Drasil::UrlMatcher do
  describe "#match?" do
    let(:url_pattern) { "/random-sellers/:id/" }
    let(:url_matcher) { Drasil::UrlMatcher.new(url, url_pattern) }

    subject { url_matcher.match? }

    context "when url matches the pattern" do
      let(:url) { "https://example.com/random-sellers/582381cc-7892-478c-a381-08d02375563e/balances/?query=John" }

      it { is_expected.to be_truthy }
    end

    context "when url doesn't match the pattern" do
      let(:url) { "https://example.com/orders" }

      it { is_expected.to be_falsey }
    end

    context "when url pattern is nil" do
      let(:url) { "https://example.com/orders" }
      let(:url_pattern) { nil }

      it { is_expected.to be_falsey }
    end

    context "when url pattern is invalid" do
      let(:url) { "https://example.com/orders" }
      let(:url_pattern) { "?[" }

      it { is_expected.to be_falsey }
    end
  end
end
