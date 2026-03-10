# frozen_string_literal: true

RSpec.describe Drasil::ResourceRegistry do
  class TestParser < Drasil::Parser
    def parse
      data = { id: 1234, name: "Test" }
      metadata = {}
      [data, metadata]
    end
  end

  class TestResource < Drasil::Base
    attributes :id, :name
  end

  class AnotherResource < Drasil::Base
    attributes :id, :title
  end

  describe "#initialize" do
    it "creates a registry with a client" do
      client = Drasil::Client.new(base_url: "https://api.example.com")
      registry = described_class.new(client)

      expect(registry).to be_a(Drasil::ResourceRegistry)
    end

    it "initializes with empty resources" do
      client = Drasil::Client.new(base_url: "https://api.example.com")
      registry = described_class.new(client)

      expect(registry.resource_names).to eq([])
    end
  end

  describe "#register" do
    context "without parser" do
      it "registers a resource" do
        client = Drasil::Client.new(base_url: "https://api.example.com")
        registry = described_class.new(client)
        result = registry.register(:tests, TestResource)

        expect(result).to be < TestResource
      end

      it "creates a scoped class" do
        client = Drasil::Client.new(base_url: "https://api.example.com")
        registry = described_class.new(client)
        scoped_class = registry.register(:tests, TestResource)

        expect(scoped_class.drasil_client).to eq(client)
      end

      it "adds resource to registry" do
        client = Drasil::Client.new(base_url: "https://api.example.com")
        registry = described_class.new(client)
        registry.register(:tests, TestResource)

        expect(registry.resource_names).to include(:tests)
      end
    end

    context "with parser" do
      it "registers the resource with parser" do
        client = Drasil::Client.new(base_url: "https://api.example.com")
        registry = described_class.new(client)
        result = registry.register(
          :tests,
          TestResource,
          parser: TestParser,
          parser_path: "/tests/*"
        )

        expect(result).to be < TestResource
      end

      it "adds parser to client configuration" do
        client = Drasil::Client.new(base_url: "https://api.example.com")
        registry = described_class.new(client)
        registry.register(
          :tests,
          TestResource,
          parser: TestParser,
          parser_path: "/tests/*"
        )

        expect(client.config.find_parser("/tests/123")).to eq(TestParser)
      end
    end

    context "with multiple resources" do
      it "registers multiple resources independently" do
        client = Drasil::Client.new(base_url: "https://api.example.com")
        registry = described_class.new(client)
        registry.register(:tests, TestResource)
        registry.register(:others, AnotherResource)

        expect(registry.resource_names).to contain_exactly(:tests, :others)
      end
    end
  end

  describe "#get" do
    context "when resource exists" do
      it "returns the scoped resource class" do
        client = Drasil::Client.new(base_url: "https://api.example.com")
        registry = described_class.new(client)
        registry.register(:tests, TestResource)
        resource_class = registry.get(:tests)

        expect(resource_class).to be < TestResource
        expect(resource_class.drasil_client).to eq(client)
      end
    end

    context "when resource does not exist" do
      it "raises ResourceNotFoundError" do
        client = Drasil::Client.new(base_url: "https://api.example.com")
        registry = described_class.new(client)

        expect { registry.get(:unknown) }.to raise_error(
          Drasil::ResourceNotFoundError,
          /Resource 'unknown' not found in registry/
        )
      end

      it "includes available resources in error message" do
        client = Drasil::Client.new(base_url: "https://api.example.com")
        registry = described_class.new(client)
        registry.register(:tests, TestResource)
        registry.register(:others, AnotherResource)

        expect { registry.get(:unknown) }.to raise_error(
          Drasil::ResourceNotFoundError,
          /Available resources: tests, others/
        )
      end
    end
  end

  describe "#registered?" do
    context "when resource is registered" do
      it "returns true" do
        client = Drasil::Client.new(base_url: "https://api.example.com")
        registry = described_class.new(client)
        registry.register(:tests, TestResource)

        expect(registry.registered?(:tests)).to be true
      end
    end

    context "when resource is not registered" do
      it "returns false" do
        client = Drasil::Client.new(base_url: "https://api.example.com")
        registry = described_class.new(client)

        expect(registry.registered?(:unknown)).to be false
      end
    end
  end

  describe "#resource_names" do
    context "with no resources" do
      it "returns empty array" do
        client = Drasil::Client.new(base_url: "https://api.example.com")
        registry = described_class.new(client)

        expect(registry.resource_names).to eq([])
      end
    end

    context "with multiple resources" do
      it "returns all registered resource names" do
        client = Drasil::Client.new(base_url: "https://api.example.com")
        registry = described_class.new(client)
        registry.register(:tests, TestResource)
        registry.register(:others, AnotherResource)

        expect(registry.resource_names).to contain_exactly(:tests, :others)
      end
    end
  end

  describe "client binding" do
    it "binds scoped resource to client" do
      client = Drasil::Client.new(base_url: "https://api.example.com")
      registry = described_class.new(client)
      scoped_class = registry.register(:tests, TestResource)

      expect(scoped_class.drasil_client).to eq(client)
    end

    it "uses client's connection" do
      client = Drasil::Client.new(base_url: "https://api.example.com")
      registry = described_class.new(client)
      scoped_class = registry.register(:tests, TestResource)

      expect(scoped_class.connection).to eq(client.connection)
    end

    it "isolates resources between different clients" do
      client1 = Drasil::Client.new(base_url: "https://api1.example.com")
      client2 = Drasil::Client.new(base_url: "https://api2.example.com")

      registry1 = described_class.new(client1)
      registry2 = described_class.new(client2)

      scoped1 = registry1.register(:tests, TestResource)
      scoped2 = registry2.register(:tests, TestResource)

      expect(scoped1.drasil_client).to eq(client1)
      expect(scoped2.drasil_client).to eq(client2)
      expect(scoped1.connection).not_to eq(scoped2.connection)
    end
  end
end
