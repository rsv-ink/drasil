# frozen_string_literal: true

RSpec.shared_examples 'a Drasil parser' do
  it 'inherits from Drasil::Parser' do
    expect(described_class.ancestors).to include(Drasil::Parser)
  end

  it 'implements parse method' do
    expect(described_class.instance_methods).to include(:parse)
  end

  it 'returns data and metadata tuple' do
    parser = described_class.new(double('response'))
    result = parser.parse

    expect(result).to be_an(Array)
    expect(result.size).to eq(2)
  end
end

RSpec.shared_examples 'a parser with pagination' do
  it 'extracts pagination metadata' do
    response = {
      data: [{ id: 1 }, { id: 2 }],
      page: 2,
      total_pages: 10
    }

    parser = described_class.new(response)
    _data, metadata = parser.parse

    expect(metadata).to include(:page, :total_pages)
  end
end

RSpec.shared_examples 'a parser with error handling' do
  it 'handles invalid response gracefully' do
    parser = described_class.new(nil)

    expect { parser.parse }.not_to raise_error
  end
end
