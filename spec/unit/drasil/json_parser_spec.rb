# frozen_string_literal: true

class JsonParserSpecParser < Drasil::Parser
  def parse
    [@response[:data], { page: @response[:page] }]
  end
end

RSpec.describe Drasil::JSONParser do
  # Minimal stand-in for Faraday::Env: on_complete only touches #body and #url
  FakeEnv = Struct.new(:body, :url)

  def run(body, client: nil, url: 'https://api.example.com/users/1')
    env = FakeEnv.new(body, URI(url))
    described_class.new(->(e) { e }, client: client).on_complete(env)
    env.body
  end

  context 'with a client' do
    it "uses the client's parser registry" do
      client = Drasil::Client.new(base_url: 'https://api.example.com')
      client.config.add_parser('/users/*', JsonParserSpecParser)

      result = run({ data: { id: 1 }, page: 3 }.to_json, client: client)

      expect(result[:data]).to eq(id: 1)
      expect(result[:metadata]).to eq(page: 3)
      expect(result[:errors]).to eq([])
    end

    it 'raises ParserNotFoundError when no pattern matches' do
      client = Drasil::Client.new(base_url: 'https://api.example.com')
      client.config.add_parser('/accounts/*', JsonParserSpecParser)

      expect { run({ data: {} }.to_json, client: client) }
        .to raise_error(Drasil::ParserNotFoundError, %r{/users/1})
    end
  end

  context 'without a client' do
    it 'falls back to the global config when parsers are registered' do
      Drasil::Config.add_parser('/users/*', JsonParserSpecParser)

      result = run({ data: { id: 2 }, page: 1 }.to_json)

      expect(result[:data]).to eq(id: 2)
    end

    it 'raises ParserNotFoundError when no parser registry is available' do
      expect { run({ data: {} }.to_json) }
        .to raise_error(Drasil::ParserNotFoundError, /No parser configuration available/)
    end
  end

  describe 'response bodies without payload' do
    it 'accepts an empty body (204 No Content)' do
      result = run('')

      expect(result[:data]).to be_nil
      expect(result[:metadata]).to eq({})
    end

    it 'accepts a nil body' do
      expect(run(nil)[:data]).to be_nil
    end

    it 'raises Drasil::ParsingError for malformed JSON' do
      expect { run('{not json') }.to raise_error(Drasil::ParsingError)
    end
  end
end
