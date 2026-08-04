# frozen_string_literal: true

RSpec.describe Drasil::ConfigResolver do
  describe '.resolve' do
    context 'when the client has the value' do
      it 'returns the client value, ignoring the global config' do
        Drasil::Config.page_query_name = :global_page
        client = Drasil::Client.new(base_url: 'https://api.example.com', page_query_name: :client_page)

        result = described_class.resolve(client, :page_query_name, default: :page)

        expect(result).to eq(:client_page)
      end
    end

    context 'when the client value is nil' do
      it 'falls back to the global config' do
        Drasil::Config.page_query_name = :global_page
        client = Drasil::Client.new(base_url: 'https://api.example.com', page_query_name: nil)

        result = described_class.resolve(client, :page_query_name, default: :page)

        expect(result).to eq(:global_page)
      end

      it 'falls back to the default when the global config is unset' do
        client = Drasil::Client.new(base_url: 'https://api.example.com', page_query_name: nil)

        result = described_class.resolve(client, :page_query_name, default: :page)

        expect(result).to eq(:page)
      end
    end

    context 'without a client' do
      it 'returns the global config when set' do
        Drasil::Config.per_page_query_name = :limit

        result = described_class.resolve(nil, :per_page_query_name, default: :per_page)

        expect(result).to eq(:limit)
      end

      it 'returns the default when the global config is unset' do
        result = described_class.resolve(nil, :per_page_query_name, default: :per_page)

        expect(result).to eq(:per_page)
      end
    end

    context 'when the key does not exist in the global config' do
      it 'returns the default' do
        result = described_class.resolve(nil, :totally_unknown_key, default: :fallback)

        expect(result).to eq(:fallback)
      end
    end
  end
end
