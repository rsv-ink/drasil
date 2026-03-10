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
      it "sets all configuration values" do
        config = described_class.new(
          base_url: "https://api.example.com",
          headers: { "Authorization" => "Bearer token" },
          include_root_in_json: true,
          page_query_name: :pg,
          per_page_query_name: :limit,
          ssl_options: { verify: true },
          proxy_options: { uri: "http://proxy.com" }
        )

        expect(config.base_url).to eq("https://api.example.com")
        expect(config.headers).to eq({ "Authorization" => "Bearer token" })
        expect(config.include_root_in_json).to eq(true)
        expect(config.page_query_name).to eq(:pg)
        expect(config.per_page_query_name).to eq(:limit)
        expect(config.ssl_options).to eq({ verify: true })
        expect(config.proxy_options).to eq({ uri: "http://proxy.com" })
      end

      it "initializes empty parsers and middlewares" do
        config = described_class.new(
          base_url: "https://api.example.com",
          headers: { "Authorization" => "Bearer token" },
          include_root_in_json: true,
          page_query_name: :pg,
          per_page_query_name: :limit,
          ssl_options: { verify: true },
          proxy_options: { uri: "http://proxy.com" }
        )

        expect(config.parsers).to eq({})
        expect(config.middlewares).to eq([])
      end
    end

    context "with defaults" do
      it "uses default values" do
        config = described_class.new

        expect(config.base_url).to be_nil
        expect(config.headers).to eq({})
        expect(config.include_root_in_json).to eq(false)
        expect(config.page_query_name).to eq(:page)
        expect(config.per_page_query_name).to eq(:per_page)
        expect(config.ssl_options).to be_nil
        expect(config.proxy_options).to be_nil
        expect(config.parsers).to eq({})
        expect(config.middlewares).to eq([])
      end
    end
  end

  describe "#add_parser" do
    context "when params are valid" do
      it "returns true" do
        config = described_class.new
        path = "/sellers/:id"
        parser = TestParser

        result = config.add_parser(path, parser)

        expect(result).to be_truthy
      end

      it "adds the parser to the registry" do
        config = described_class.new
        path = "/sellers/:id"
        parser = TestParser

        config.add_parser(path, parser)

        expect(config.parsers[path]).to eq(parser)
      end
    end

    context "when params are invalid" do
      context "when path is invalid" do
        it "raises RegexpError" do
          config = described_class.new
          path = "?["
          parser = TestParser

          expect { config.add_parser(path, parser) }.to raise_error(RegexpError)
        end
      end

      context "when parser is invalid" do
        context "when parser is nil" do
          it "raises ArgumentError" do
            config = described_class.new
            path = "/sellers/:id"
            parser = nil

            expect { config.add_parser(path, parser) }.to raise_error(ArgumentError, "Parser cannot be nil")
          end
        end

        context "when parser is not a Parser" do
          it "raises ArgumentError" do
            config = described_class.new
            path = "/sellers/:id"
            parser = InvalidParser

            expect { config.add_parser(path, parser) }.to raise_error(ArgumentError, "Parser is not a parser")
          end
        end
      end
    end
  end

  describe "#add_middleware" do
    it "adds middleware to the middlewares array" do
      config = described_class.new
      middleware = double("Middleware")

      config.add_middleware(middleware)

      expect(config.middlewares).to include(middleware)
    end

    it "allows multiple middlewares" do
      config = described_class.new
      middleware = double("Middleware")
      middleware2 = double("Middleware2")

      config.add_middleware(middleware)
      config.add_middleware(middleware2)

      expect(config.middlewares).to eq([middleware, middleware2])
    end
  end

  describe "#parse" do
    class ConfigurationTestParser < Drasil::Parser
      def parse
        data = @response
        metadata = { page: 1, total_pages: 10 }
        [data, metadata]
      end
    end

    context "when there is a matching parser" do
      it "returns data and metadata" do
        config = described_class.new
        config.add_parser("/sellers/:id", ConfigurationTestParser)

        url = "/sellers/1234"
        response = {
          id: 1234,
          first_name: "John",
          last_name: "Chico"
        }

        data, metadata = config.parse(url, response)

        expect(data[:id]).to eq(1234)
        expect(data[:first_name]).to eq("John")
        expect(data[:last_name]).to eq("Chico")
        expect(metadata[:page]).to eq(1)
        expect(metadata[:total_pages]).to eq(10)
      end
    end

    context "when there is no matching parser" do
      it "raises ParserNotFoundError" do
        config = described_class.new
        config.add_parser("/sellers/:id", ConfigurationTestParser)

        url = "/unknown/path"
        response = {}

        expect { config.parse(url, response) }.to raise_error(
          Drasil::ParserNotFoundError,
          "No parser found for URL: /unknown/path"
        )
      end
    end
  end

  describe "#find_parser" do
    context "when there is a matching parser" do
      it "returns the parser class" do
        config = described_class.new
        config.add_parser("/sellers/:id", TestParser)

        parser_class = config.find_parser("/sellers/1234")

        expect(parser_class).to eq(TestParser)
      end
    end

    context "when there is no matching parser" do
      it "raises ParserNotFoundError" do
        config = described_class.new
        config.add_parser("/sellers/:id", TestParser)

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
