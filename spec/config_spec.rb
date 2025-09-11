# frozen_string_literal: true

RSpec.describe Drasil::Config do
  class TestParser < Drasil::Parser
    def parse
      data = {
        id: 1234,
        first_name: "John",
        last_name: "Chico"
      }
      metadata = {}

      [data, metadata]
    end
  end
  class InvalidParser; end

  describe "#add_parser" do
    let(:parser) { TestParser }

    subject { Drasil::Config.add_parser(path, parser) }

    context "when params are valid" do
      let(:path) { "/sellers/:id" }

      it { is_expected.to be_truthy }
    end

    context "when params are invalid" do
      context "when path is invalid" do
        let(:path) { "?[" }

        it { expect { subject }.to raise_error(RegexpError) }
      end

      context "when parser is invalid" do
        let(:path) { "/sellers/:id" }
        let(:parser) { nil }

        context "when parser is nil" do
          it { expect { subject }.to raise_error(ArgumentError) }
        end

        context "when parser is not a Parser" do
          let(:parser) { InvalidParser }

          it { expect { subject }.to raise_error(ArgumentError) }
        end
      end
    end
  end

  describe "#parse" do
    before do
      Drasil::Config.add_parser "/sellers/:id", TestParser
    end

    let(:url_pattern) { "/sellers/1234" }
    let(:response) do
      {
        id: 1234,
        first_name: "John",
        last_name: "Chico"
      }
    end

    subject { Drasil::Config.parse(url_pattern, response) }

    context "when there is a matching parser" do
      it "retuns data and metadata" do
        data, metadata = subject

        expect(data[:id]).to eq 1234
        expect(data[:first_name]).to eq "John"
        expect(data[:last_name]).to eq "Chico"
        expect(metadata.size).to eq 0
      end
    end
  end
end
