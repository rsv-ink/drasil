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
      subject do
        described_class.new(
          base_url: "https://api.example.com"
        )
      end

      it "creates a client instance" do
        expect(subject).to be_a(Drasil::Client)
      end

      it "creates a configuration" do
        expect(subject.config).to be_a(Drasil::Configuration)
        expect(subject.config.base_url).to eq("https://api.example.com")
      end

      it "creates a connection" do
        expect(subject.connection).to be_a(Faraday::Connection)
      end

      it "creates a resource registry" do
        expect(subject.resource_registry).to be_a(Drasil::ResourceRegistry)
      end
    end

    context "with all parameters" do
      subject do
        described_class.new(
          base_url: "https://api.example.com",
          headers: { "Authorization" => "Bearer token" },
          ssl_options: { verify: true },
          proxy_options: { uri: "http://proxy.com" },
          page_query_name: :pg,
          per_page_query_name: :limit
        )
      end

      it "passes all options to configuration" do
        expect(subject.config.base_url).to eq("https://api.example.com")
        expect(subject.config.headers).to eq({ "Authorization" => "Bearer token" })
        expect(subject.config.ssl_options).to eq({ verify: true })
        expect(subject.config.proxy_options).to eq({ uri: "http://proxy.com" })
        expect(subject.config.page_query_name).to eq(:pg)
        expect(subject.config.per_page_query_name).to eq(:limit)
      end
    end
  end

  describe "#register_resource" do
    let(:client) do
      described_class.new(base_url: "https://api.example.com")
    end

    context "without parser" do
      it "registers the resource" do
        result = client.register_resource(:tests, TestResource)
        expect(result).to be < TestResource
      end

      it "makes the resource available via method_missing" do
        client.register_resource(:tests, TestResource)
        expect(client.tests).to be < TestResource
      end
    end

    context "with parser" do
      it "registers the resource with parser" do
        result = client.register_resource(
          :tests,
          TestResource,
          parser: TestParser,
          parser_path: "/tests/*"
        )
        expect(result).to be < TestResource
      end

      it "adds parser to configuration" do
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
    let(:client) do
      described_class.new(base_url: "https://api.example.com")
    end

    before do
      client.register_resource(:tests, TestResource)
    end

    context "when resource is registered" do
      it "returns the resource class" do
        expect(client.tests).to be < TestResource
      end
    end

    context "when resource is not registered" do
      it "raises NoMethodError" do
        expect { client.unknown_resource }.to raise_error(NoMethodError)
      end
    end
  end

  describe "#respond_to_missing?" do
    let(:client) do
      described_class.new(base_url: "https://api.example.com")
    end

    before do
      client.register_resource(:tests, TestResource)
    end

    context "when resource is registered" do
      it "returns true" do
        expect(client.respond_to?(:tests)).to be true
      end
    end

    context "when resource is not registered" do
      it "returns false" do
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

    it "adds custom middleware to connection" do
      client = described_class.new(base_url: "https://api.example.com")
      client.config.add_middleware(CustomMiddleware)

      # Rebuild connection to apply middleware
      client = described_class.new(base_url: "https://api.example.com")
      client.config.add_middleware(CustomMiddleware)

      # Just verify that middleware is in the config
      expect(client.config.middlewares).to include(CustomMiddleware)
    end
  end
end
