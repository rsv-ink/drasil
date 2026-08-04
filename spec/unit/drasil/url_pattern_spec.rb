# frozen_string_literal: true

RSpec.describe Drasil::UrlPattern do
  describe '#match?' do
    # pattern => { url => expected }
    {
      '/users/:id' => {
        '/users/1' => true,
        'https://api.example.com/users/1' => true,
        'https://api.example.com/v1/users/1' => true,
        'https://api.example.com/users/1?full=true' => true,
        '/users' => false,
        '/users_archive/1' => false
      },
      '/users/*' => {
        '/users' => true,
        '/users/1' => true,
        'https://api.example.com/v1/users/abc' => true,
        '/usersXYZ' => false,
        '/admin/users_backup' => false,
        '/accounts/1' => false
      },
      '/users/**' => {
        '/users/1/posts/2' => true,
        '/users' => false
      },
      '/sellers/:id/' => {
        # a trailing slash keeps the historical prefix behaviour
        'https://example.com/sellers/582381cc/balances/?query=John' => true,
        '/sellers/582381cc/' => true
      }
    }.each do |pattern, expectations|
      context "with pattern #{pattern.inspect}" do
        expectations.each do |url, expected|
          it "returns #{expected} for #{url.inspect}" do
            expect(described_class.new(pattern).match?(url)).to eq(expected)
          end
        end
      end
    end

    it 'returns false for a nil url' do
      expect(described_class.new('/users/:id').match?(nil)).to be false
    end
  end

  describe '#initialize' do
    it 'raises ArgumentError when the pattern is blank' do
      expect { described_class.new(nil) }.to raise_error(ArgumentError)
      expect { described_class.new('') }.to raise_error(ArgumentError)
    end

    it 'raises RegexpError for a malformed pattern' do
      expect { described_class.new('?[') }.to raise_error(RegexpError)
    end

    it 'treats regex metacharacters as literals' do
      pattern = described_class.new('/users.json')

      expect(pattern.match?('/users.json')).to be true
      expect(pattern.match?('/usersXjson')).to be false
    end
  end
end
