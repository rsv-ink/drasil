# frozen_string_literal: true

RSpec.describe Drasil::Client do
  class TestParser < Drasil::Parser
    def parse
      data = { id: 1234, name: "Test" }
      metadata = { page: 1, total_pages: 10 }
      [data, metadata]
    end
  end

  class TestResource < Drasil::Base
    attributes :id, :name
  end

  describe "#initialize" do
    context "with required parameters" do
      it "creates a client instance" do
        client = described_class.new(base_url: "https://api.example.com")

        expect(client).to be_a(Drasil::Client)
      end

      it "creates a configuration" do
        client = described_class.new(base_url: "https://api.example.com")

        expect(client.config).to be_a(Drasil::Configuration)
        expect(client.config.base_url).to eq("https://api.example.com")
      end

      it "creates a connection" do
        client = described_class.new(base_url: "https://api.example.com")

        expect(client.connection).to be_a(Faraday::Connection)
      end

      it "creates a resource registry" do
        client = described_class.new(base_url: "https://api.example.com")

        expect(client.resource_registry).to be_a(Drasil::ResourceRegistry)
      end
    end

    context "with all parameters" do
      it "passes all options to configuration" do
        client = described_class.new(
          base_url: "https://api.example.com",
          headers: { "Authorization" => "Bearer token" },
          ssl_options: { verify: true },
          proxy_options: { uri: "http://proxy.com" },
          page_query_name: :pg,
          per_page_query_name: :limit
        )

        expect(client.config.base_url).to eq("https://api.example.com")
        expect(client.config.headers).to eq({ "Authorization" => "Bearer token" })
        expect(client.config.ssl_options).to eq({ verify: true })
        expect(client.config.proxy_options).to eq({ uri: "http://proxy.com" })
        expect(client.config.page_query_name).to eq(:pg)
        expect(client.config.per_page_query_name).to eq(:limit)
      end
    end
  end

  describe "#register_resource" do
    context "without parser" do
      it "registers the resource" do
        client = described_class.new(base_url: "https://api.example.com")
        result = client.register_resource(:tests, TestResource)

        expect(result).to be < TestResource
      end

      it "makes the resource available via method_missing" do
        client = described_class.new(base_url: "https://api.example.com")
        client.register_resource(:tests, TestResource)

        expect(client.tests).to be < TestResource
      end
    end

    context "with parser" do
      it "registers the resource with parser" do
        client = described_class.new(base_url: "https://api.example.com")
        result = client.register_resource(
          :tests,
          TestResource,
          parser: TestParser,
          parser_path: "/tests/*"
        )

        expect(result).to be < TestResource
      end

      it "adds parser to configuration" do
        client = described_class.new(base_url: "https://api.example.com")
        client.register_resource(
          :tests,
          TestResource,
          parser: TestParser,
          parser_path: "/tests/*"
        )

        expect(client.config.find_parser("/tests/123")).to eq(TestParser)
      end
    end
  end

  describe "#method_missing" do
    context "when resource is registered" do
      it "returns the resource class" do
        client = described_class.new(base_url: "https://api.example.com")
        client.register_resource(:tests, TestResource)

        expect(client.tests).to be < TestResource
      end
    end

    context "when resource is not registered" do
      it "raises NoMethodError" do
        client = described_class.new(base_url: "https://api.example.com")

        expect { client.unknown_resource }.to raise_error(NoMethodError)
      end
    end
  end

  describe "#respond_to_missing?" do
    context "when resource is registered" do
      it "returns true" do
        client = described_class.new(base_url: "https://api.example.com")
        client.register_resource(:tests, TestResource)

        expect(client.respond_to?(:tests)).to be true
      end
    end

    context "when resource is not registered" do
      it "returns false" do
        client = described_class.new(base_url: "https://api.example.com")

        expect(client.respond_to?(:unknown_resource)).to be false
      end
    end
  end

  describe "connection isolation" do
    it "creates isolated connections for different clients" do
      client1 = described_class.new(
        base_url: "https://api1.example.com",
        headers: { "X-Client" => "1" }
      )

      client2 = described_class.new(
        base_url: "https://api2.example.com",
        headers: { "X-Client" => "2" }
      )

      expect(client1.connection).not_to eq(client2.connection)
      expect(client1.connection.url_prefix.to_s).to eq("https://api1.example.com/")
      expect(client2.connection.url_prefix.to_s).to eq("https://api2.example.com/")
    end
  end

  describe "parser isolation" do
    class Parser1 < Drasil::Parser
      def parse
        [{ version: 1 }, {}]
      end
    end

    class Parser2 < Drasil::Parser
      def parse
        [{ version: 2 }, {}]
      end
    end

    it "maintains separate parser registries for different clients" do
      client1 = described_class.new(base_url: "https://api.example.com")
      client1.register_resource(
        :tests,
        TestResource,
        parser: Parser1,
        parser_path: "/tests/*"
      )

      client2 = described_class.new(base_url: "https://api.example.com")
      client2.register_resource(
        :tests,
        TestResource,
        parser: Parser2,
        parser_path: "/tests/*"
      )

      expect(client1.config.find_parser("/tests/123")).to eq(Parser1)
      expect(client2.config.find_parser("/tests/123")).to eq(Parser2)
    end
  end

  describe "middleware support" do
    class CustomMiddleware < Faraday::Middleware
      def call(env)
        env.request_headers["X-Custom"] = "test"
        @app.call(env)
      end
    end

    context "when configured with a block before connection builds" do
      it "applies middleware to actual HTTP requests" do
        client = described_class.new(base_url: "https://api.example.com") do |config|
          config.add_middleware(CustomMiddleware)
          config.add_parser("/test", TestParser)
        end

        stub_request(:get, "https://api.example.com/test")
          .with(headers: { "X-Custom" => "test" })
          .to_return(status: 200, body: '{"data": {}}')

        client.connection.get("/test")

        expect(WebMock).to have_requested(:get, "https://api.example.com/test")
          .with(headers: { "X-Custom" => "test" })
      end

      it "supports middleware with options" do
        middleware_with_options = [CustomMiddleware, { option: "value" }]

        client = described_class.new(base_url: "https://api.example.com") do |config|
          config.add_middleware(middleware_with_options)
        end

        expect(client.config.middlewares).to include(middleware_with_options)
      end

      it "allows adding parsers in the same block" do
        parser_class = Class.new(Drasil::Parser) do
          def parse
            [parsed_data, {}]
          end
        end

        client = described_class.new(base_url: "https://api.example.com") do |config|
          config.add_middleware(CustomMiddleware)
          config.add_parser("/test/*", parser_class)
        end

        expect(client.config.middlewares).to include(CustomMiddleware)
        expect(client.config.find_parser("/test/123")).to eq(parser_class)
      end
    end

    context "deprecated: when added after client initialization" do
      it "adds to config but does NOT affect the connection" do
        client = described_class.new(base_url: "https://api.example.com") do |config|
          config.add_parser("/test", TestParser)
        end
        client.config.add_middleware(CustomMiddleware)

        # Middleware is in config
        expect(client.config.middlewares).to include(CustomMiddleware)

        # But it's NOT applied to requests (connection was already built)
        stub_request(:get, "https://api.example.com/test")
          .to_return(status: 200, body: '{"data": {}}')

        client.connection.get("/test")

        # X-Custom header was NOT added because middleware wasn't in the connection
        expect(WebMock).to have_requested(:get, "https://api.example.com/test")
          .with { |req| req.headers["X-Custom"].nil? }
      end
    end
  end
end
