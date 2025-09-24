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

  describe "SSL and Proxy Configuration" do
    before(:each) do
      Drasil::Config.ssl_options = nil
      Drasil::Config.proxy_options = nil
    end

    context 'when SSL options are configured' do
      it 'accepts SSL configuration' do
        ssl_options = {
          verify: true,
          ca_file: "/path/to/ca-bundle.crt",
          client_cert: "/path/to/client.crt",
          client_key: "/path/to/client.key",
          version: :TLSv1_2
        }

        Drasil.configure do |config|
          config.base_url = "https://api.example.com"
          config.headers = { "Authorization" => "Bearer test" }
          config.ssl_options = ssl_options
          config.add_parser "/test", TestParser
        end

        expect(Drasil::Config.ssl_options).to eq(ssl_options)
      end
    end

    context 'when proxy options are configured' do
      it 'accepts proxy configuration' do
        proxy_options = {
          uri: "http://proxy.example.com:8080",
          user: "proxy_user",
          password: "proxy_pass"
        }

        Drasil.configure do |config|
          config.base_url = "https://api.example.com"
          config.headers = { "Authorization" => "Bearer test" }
          config.proxy_options = proxy_options
          config.add_parser "/test", TestParser
        end

        expect(Drasil::Config.proxy_options).to eq(proxy_options)
      end
    end

    context 'when both SSL and proxy options are configured' do
      it 'accepts both configurations' do
        ssl_options = { verify: true }
        proxy_options = { uri: "http://proxy.example.com:8080" }

        Drasil.configure do |config|
          config.base_url = "https://api.example.com"
          config.headers = { "Authorization" => "Bearer test" }
          config.ssl_options = ssl_options
          config.proxy_options = proxy_options
          config.add_parser "/test", TestParser
        end

        expect(Drasil::Config.ssl_options).to eq(ssl_options)
        expect(Drasil::Config.proxy_options).to eq(proxy_options)
      end
    end

    context 'when no SSL or proxy options are configured' do
      it 'works without SSL and proxy configurations' do
        Drasil.configure do |config|
          config.base_url = "https://api.example.com"
          config.headers = { "Authorization" => "Bearer test" }
          config.add_parser "/test", TestParser
        end

        expect(Drasil::Config.ssl_options).to be_nil
        expect(Drasil::Config.proxy_options).to be_nil
      end
    end
  end
end
