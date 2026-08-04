require "spec_helper"

RSpec.describe PaymentsApiClient::Seller do
  # Resources are reached through the client, which binds them to its own
  # connection and parser registry.
  subject(:sellers) { PaymentsApiClient.client.sellers }

  describe "#find" do
    context "when seller exists" do
      before do
        mock_request(:get, "/sellers/1234")
          .to_return(status: 200, body: fixture("sellers/200.json"))
      end

      it { expect(sellers.find("1234")).to be_a(PaymentsApiClient::Seller) }
      it { expect(sellers.find("1234").attributes).to match_fixture("sellers/200.json") }
    end

    context "when seller does not exist" do
      before do
        mock_request(:get, "/sellers/1234")
          .to_return(status: 404, body: fixture("sellers/404.json"))
      end

      it { expect { sellers.find("1234") }.to raise_error(Drasil::ResourceNotFound) }
    end
  end
end
