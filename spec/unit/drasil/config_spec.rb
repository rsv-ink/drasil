# frozen_string_literal: true

RSpec.describe Drasil::Config do
  class ConfigTestParser < Drasil::Parser
    def parse
      data = @response
      metadata = {}

      [data, metadata]
    end
  end
  class InvalidParser; end

  describe "#add_parser" do
    context "when params are valid" do
      it "returns true" do
        path = "/sellers/:id"
        parser = ConfigTestParser

        result = Drasil::Config.add_parser(path, parser)

        expect(result).to be_truthy
      end
    end

    context "when params are invalid" do
      context "when path is invalid" do
        it "raises RegexpError" do
          path = "?["
          parser = ConfigTestParser

          expect { Drasil::Config.add_parser(path, parser) }.to raise_error(RegexpError)
        end
      end

      context "when parser is invalid" do
        context "when parser is nil" do
          it "raises ArgumentError" do
            path = "/sellers/:id"
            parser = nil

            expect { Drasil::Config.add_parser(path, parser) }.to raise_error(ArgumentError)
          end
        end

        context "when parser is not a Parser" do
          it "raises ArgumentError" do
            path = "/sellers/:id"
            parser = InvalidParser

            expect { Drasil::Config.add_parser(path, parser) }.to raise_error(ArgumentError)
          end
        end
      end
    end
  end

  describe "#parse" do
    context "when there is a matching parser" do
      it "retuns data and metadata" do
        # Clear parsers before test
        Drasil::Config.instance_variable_set(:@parsers, {})
        Drasil::Config.add_parser "/sellers/:id", ConfigTestParser

        url_pattern = "/sellers/1234"
        response = {
          id: 1234,
          first_name: "John",
          last_name: "Chico"
        }

        data, metadata = Drasil::Config.parse(url_pattern, response)

        expect(data[:id]).to eq 1234
        expect(data[:first_name]).to eq "John"
        expect(data[:last_name]).to eq "Chico"
        expect(metadata.size).to eq 0
      end
    end
  end

  describe "SSL and Proxy Configuration" do
    context 'when SSL options are configured' do
      it 'accepts SSL configuration' do
        Drasil::Config.ssl_options = nil
        Drasil::Config.proxy_options = nil

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
          config.add_parser "/test", ConfigTestParser
        end

        expect(Drasil::Config.ssl_options).to eq(ssl_options)
      end
    end

    context 'when proxy options are configured' do
      it 'accepts proxy configuration' do
        Drasil::Config.ssl_options = nil
        Drasil::Config.proxy_options = nil

        proxy_options = {
          uri: "http://proxy.example.com:8080",
          user: "proxy_user",
          password: "proxy_pass"
        }

        Drasil.configure do |config|
          config.base_url = "https://api.example.com"
          config.headers = { "Authorization" => "Bearer test" }
          config.proxy_options = proxy_options
          config.add_parser "/test", ConfigTestParser
        end

        expect(Drasil::Config.proxy_options).to eq(proxy_options)
      end
    end

    context 'when both SSL and proxy options are configured' do
      it 'accepts both configurations' do
        Drasil::Config.ssl_options = nil
        Drasil::Config.proxy_options = nil

        ssl_options = { verify: true }
        proxy_options = { uri: "http://proxy.example.com:8080" }

        Drasil.configure do |config|
          config.base_url = "https://api.example.com"
          config.headers = { "Authorization" => "Bearer test" }
          config.ssl_options = ssl_options
          config.proxy_options = proxy_options
          config.add_parser "/test", ConfigTestParser
        end

        expect(Drasil::Config.ssl_options).to eq(ssl_options)
        expect(Drasil::Config.proxy_options).to eq(proxy_options)
      end
    end

    context 'when no SSL or proxy options are configured' do
      it 'works without SSL and proxy configurations' do
        Drasil::Config.ssl_options = nil
        Drasil::Config.proxy_options = nil

        Drasil.configure do |config|
          config.base_url = "https://api.example.com"
          config.headers = { "Authorization" => "Bearer test" }
          config.add_parser "/test", ConfigTestParser
        end

        expect(Drasil::Config.ssl_options).to be_nil
        expect(Drasil::Config.proxy_options).to be_nil
      end
    end
  end
end
