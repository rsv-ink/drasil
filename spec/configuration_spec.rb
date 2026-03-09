# frozen_string_literal: true

RSpec.describe Drasil::Configuration do
  class TestParser < Drasil::Parser
    def parse
      data = {
        id: 1234,
        first_name: "John",
        last_name: "Chico"
      }
      metadata = { page: 1, total_pages: 10 }

      [data, metadata]
    end
  end

  class InvalidParser; end

  describe "#initialize" do
    context "with all parameters" do
      subject do
        described_class.new(
          base_url: "https://api.example.com",
          headers: { "Authorization" => "Bearer token" },
          include_root_in_json: true,
          page_query_name: :pg,
          per_page_query_name: :limit,
          ssl_options: { verify: true },
          proxy_options: { uri: "http://proxy.com" }
        )
      end

      it "sets all configuration values" do
        expect(subject.base_url).to eq("https://api.example.com")
        expect(subject.headers).to eq({ "Authorization" => "Bearer token" })
        expect(subject.include_root_in_json).to eq(true)
        expect(subject.page_query_name).to eq(:pg)
        expect(subject.per_page_query_name).to eq(:limit)
        expect(subject.ssl_options).to eq({ verify: true })
        expect(subject.proxy_options).to eq({ uri: "http://proxy.com" })
      end

      it "initializes empty parsers and middlewares" do
        expect(subject.parsers).to eq({})
        expect(subject.middlewares).to eq([])
      end
    end

    context "with defaults" do
      subject { described_class.new }

      it "uses default values" do
        expect(subject.base_url).to be_nil
        expect(subject.headers).to eq({})
        expect(subject.include_root_in_json).to eq(false)
        expect(subject.page_query_name).to eq(:page)
        expect(subject.per_page_query_name).to eq(:per_page)
        expect(subject.ssl_options).to be_nil
        expect(subject.proxy_options).to be_nil
        expect(subject.parsers).to eq({})
        expect(subject.middlewares).to eq([])
      end
    end
  end

  describe "#add_parser" do
    let(:config) { described_class.new }
    let(:parser) { TestParser }

    subject { config.add_parser(path, parser) }

    context "when params are valid" do
      let(:path) { "/sellers/:id" }

      it "returns true" do
        expect(subject).to be_truthy
      end

      it "adds the parser to the registry" do
        subject
        expect(config.parsers[path]).to eq(parser)
      end
    end

    context "when params are invalid" do
      context "when path is invalid" do
        let(:path) { "?[" }

        it "raises RegexpError" do
          expect { subject }.to raise_error(RegexpError)
        end
      end

      context "when parser is invalid" do
        let(:path) { "/sellers/:id" }

        context "when parser is nil" do
          let(:parser) { nil }

          it "raises ArgumentError" do
            expect { subject }.to raise_error(ArgumentError, "Parser cannot be nil")
          end
        end

        context "when parser is not a Parser" do
          let(:parser) { InvalidParser }

          it "raises ArgumentError" do
            expect { subject }.to raise_error(ArgumentError, "Parser is not a parser")
          end
        end
      end
    end
  end

  describe "#add_middleware" do
    let(:config) { described_class.new }
    let(:middleware) { double("Middleware") }

    it "adds middleware to the middlewares array" do
      config.add_middleware(middleware)
      expect(config.middlewares).to include(middleware)
    end

    it "allows multiple middlewares" do
      middleware2 = double("Middleware2")
      config.add_middleware(middleware)
      config.add_middleware(middleware2)
      expect(config.middlewares).to eq([middleware, middleware2])
    end
  end

  describe "#parse" do
    # Create a fresh config for each test to avoid contamination
    let(:config) { described_class.new }

    # Use a unique parser class for this test suite
    class ConfigurationTestParser < Drasil::Parser
      def parse
        data = @response
        metadata = { page: 1, total_pages: 10 }
        [data, metadata]
      end
    end

    before do
      config.add_parser("/sellers/:id", ConfigurationTestParser)
    end

    let(:url) { "/sellers/1234" }
    let(:response) do
      {
        id: 1234,
        first_name: "John",
        last_name: "Chico"
      }
    end

    subject { config.parse(url, response) }

    context "when there is a matching parser" do
      it "returns data and metadata" do
        data, metadata = subject

        expect(data[:id]).to eq(1234)
        expect(data[:first_name]).to eq("John")
        expect(data[:last_name]).to eq("Chico")
        expect(metadata[:page]).to eq(1)
        expect(metadata[:total_pages]).to eq(10)
      end
    end

    context "when there is no matching parser" do
      let(:url) { "/unknown/path" }

      it "raises ParserNotFoundError" do
        expect { subject }.to raise_error(
          Drasil::ParserNotFoundError,
          "No parser found for URL: /unknown/path"
        )
      end
    end
  end

  describe "#find_parser" do
    let(:config) { described_class.new }

    before do
      config.add_parser("/sellers/:id", TestParser)
    end

    context "when there is a matching parser" do
      it "returns the parser class" do
        parser_class = config.find_parser("/sellers/1234")
        expect(parser_class).to eq(TestParser)
      end
    end

    context "when there is no matching parser" do
      it "raises ParserNotFoundError" do
        expect { config.find_parser("/unknown/path") }.to raise_error(
          Drasil::ParserNotFoundError,
          "No parser found for URL: /unknown/path"
        )
      end
    end
  end

  describe "SSL and Proxy Configuration" do
    context "when SSL options are configured" do
      it "accepts SSL configuration" do
        ssl_options = {
          verify: true,
          ca_file: "/path/to/ca-bundle.crt",
          client_cert: "/path/to/client.crt",
          client_key: "/path/to/client.key",
          version: :TLSv1_2
        }

        config = described_class.new(ssl_options: ssl_options)

        expect(config.ssl_options).to eq(ssl_options)
      end
    end

    context "when proxy options are configured" do
      it "accepts proxy configuration" do
        proxy_options = {
          uri: "http://proxy.example.com:8080",
          user: "proxy_user",
          password: "proxy_pass"
        }

        config = described_class.new(proxy_options: proxy_options)

        expect(config.proxy_options).to eq(proxy_options)
      end
    end

    context "when both SSL and proxy options are configured" do
      it "accepts both configurations" do
        ssl_options = { verify: true }
        proxy_options = { uri: "http://proxy.example.com:8080" }

        config = described_class.new(
          ssl_options: ssl_options,
          proxy_options: proxy_options
        )

        expect(config.ssl_options).to eq(ssl_options)
        expect(config.proxy_options).to eq(proxy_options)
      end
    end

    context "when no SSL or proxy options are configured" do
      it "works without SSL and proxy configurations" do
        config = described_class.new

        expect(config.ssl_options).to be_nil
        expect(config.proxy_options).to be_nil
      end
    end
  end
end
