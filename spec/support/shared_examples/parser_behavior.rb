# frozen_string_literal: true

# Shared behaviour for parser classes.
#
# The including group must define a `parser_class` and a `sample_response` it can
# actually parse:
#
#   describe MyParser do
#     let(:parser_class) { MyParser }
#     let(:sample_response) { { data: [{ id: 1 }], page: 1, total_pages: 2 } }
#
#     it_behaves_like 'a Drasil parser'
#   end
RSpec.shared_examples 'a Drasil parser' do
  it 'inherits from Drasil::Parser' do
    expect(parser_class.ancestors).to include(Drasil::Parser)
  end

  it 'implements the parse method' do
    expect(parser_class.instance_methods).to include(:parse)
  end

  it 'returns a [data, metadata] tuple' do
    result = parser_class.new(sample_response).parse

    expect(result).to be_an(Array)
    expect(result.size).to eq(2)
    expect(result.last).to be_a(Hash)
  end
end

RSpec.shared_examples 'a parser with pagination' do
  it 'extracts pagination metadata' do
    _data, metadata = parser_class.new(sample_response).parse

    expect(metadata).to include(:page, :total_pages)
  end
end
