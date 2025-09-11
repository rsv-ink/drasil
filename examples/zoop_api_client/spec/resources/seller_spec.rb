require "spec_helper"

RSpec.describe ZoopApiClient::Seller do
  describe "#find" do
    context "when seller exists" do
      before do
        mock_request(:get, "/sellers/1234")
          .to_return(status: 200, body: fixture("sellers/200.json"))
      end

      subject { ZoopApiClient::Seller.find("1234") }

      it { expect(subject).to be_a(ZoopApiClient::Seller) }
      it { expect(subject.attributes).to match_fixture("sellers/200.json") }
    end

    context "when seller does not exist" do
      before do
        mock_request(:get, "/sellers/1234")
          .to_return(status: 404, body: fixture("sellers/404.json"))
      end

      subject { ZoopApiClient::Seller.find("1234") }

      it { expect { subject }.to raise_error(Faraday::ResourceNotFound) }
    end
  end
end
