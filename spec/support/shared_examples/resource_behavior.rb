# frozen_string_literal: true

# Shared behaviour for resource classes.
#
# The including group must define a `resource_class` (and a `client` for the
# scoped variant):
#
#   describe 'the scoped class' do
#     let(:resource_class) { client.register_resource(:users, User) }
#
#     it_behaves_like 'a Drasil resource'
#     it_behaves_like 'a scoped resource'
#   end
RSpec.shared_examples "a Drasil resource" do
  it "inherits from Drasil::Base" do
    expect(resource_class.ancestors).to include(Drasil::Base)
  end

  it "has a drasil_client reader" do
    expect(resource_class).to respond_to(:drasil_client)
  end

  it "has a usable connection" do
    expect(resource_class.connection).to be_a(Faraday::Connection)
  end
end

RSpec.shared_examples "a resource with CRUD operations" do
  it "responds to the CRUD entry points" do
    expect(resource_class).to respond_to(:find, :all, :create)
  end

  it "serializes params for writes without raising" do
    expect { resource_class.new(id: 1).to_params }.not_to raise_error
  end
end

RSpec.shared_examples "a scoped resource" do
  it "is bound to the client" do
    expect(resource_class.drasil_client).to eq(client)
  end

  it "uses the client's connection" do
    expect(resource_class.connection).to be(client.connection)
  end

  it "is isolated from other clients" do
    other_client = Drasil::Client.new(base_url: "https://other.example.com")

    expect(resource_class.connection).not_to eq(other_client.connection)
  end
end
