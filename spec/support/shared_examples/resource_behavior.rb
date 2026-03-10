# frozen_string_literal: true

RSpec.shared_examples "a Drasil resource" do
  it "has a drasil_client" do
    expect(described_class).to respond_to(:drasil_client)
  end

  it "has a connection" do
    expect(described_class).to respond_to(:connection)
  end

  it "inherits from Drasil::Base" do
    expect(described_class.ancestors).to include(Drasil::Base)
  end
end

RSpec.shared_examples "a resource with CRUD operations" do
  describe "CRUD operations" do
    it "responds to find" do
      expect(described_class).to respond_to(:find)
    end

    it "responds to all" do
      expect(described_class).to respond_to(:all)
    end

    it "responds to create" do
      expect(described_class).to respond_to(:create)
    end
  end
end

RSpec.shared_examples "a scoped resource" do |client|
  it "is bound to the client" do
    expect(described_class.drasil_client).to eq(client)
  end

  it "uses client's connection" do
    expect(described_class.connection).to eq(client.connection)
  end

  it "is isolated from other clients" do
    other_client = Drasil::Client.new(base_url: "https://other.example.com")
    expect(described_class.connection).not_to eq(other_client.connection)
  end
end
