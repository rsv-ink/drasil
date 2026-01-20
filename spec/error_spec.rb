# frozen_string_literal: true

RSpec.describe 'Drasil Error Classes' do
  describe 'HTTP Error Classes' do
    describe Drasil::BadRequestError do
      it 'is defined' do
        expect(defined?(Drasil::BadRequestError)).to eq('constant')
      end

      it 'inherits from Faraday::BadRequestError' do
        expect(Drasil::BadRequestError.superclass).to eq(Faraday::BadRequestError)
      end

      it 'can be raised with a message' do
        expect { raise Drasil::BadRequestError, 'test error' }.to raise_error(Drasil::BadRequestError, 'test error')
      end
    end

    describe Drasil::UnauthorizedError do
      it 'is defined' do
        expect(defined?(Drasil::UnauthorizedError)).to eq('constant')
      end

      it 'inherits from Faraday::UnauthorizedError' do
        expect(Drasil::UnauthorizedError.superclass).to eq(Faraday::UnauthorizedError)
      end
    end

    describe Drasil::ForbiddenError do
      it 'is defined' do
        expect(defined?(Drasil::ForbiddenError)).to eq('constant')
      end

      it 'inherits from Faraday::ForbiddenError' do
        expect(Drasil::ForbiddenError.superclass).to eq(Faraday::ForbiddenError)
      end
    end

    describe Drasil::ResourceNotFound do
      it 'is defined' do
        expect(defined?(Drasil::ResourceNotFound)).to eq('constant')
      end

      it 'inherits from Faraday::ResourceNotFound' do
        expect(Drasil::ResourceNotFound.superclass).to eq(Faraday::ResourceNotFound)
      end
    end

    describe Drasil::ConflictError do
      it 'is defined' do
        expect(defined?(Drasil::ConflictError)).to eq('constant')
      end

      it 'inherits from Faraday::ConflictError' do
        expect(Drasil::ConflictError.superclass).to eq(Faraday::ConflictError)
      end
    end

    describe Drasil::UnprocessableEntityError do
      it 'is defined' do
        expect(defined?(Drasil::UnprocessableEntityError)).to eq('constant')
      end

      it 'inherits from Faraday::UnprocessableEntityError' do
        expect(Drasil::UnprocessableEntityError.superclass).to eq(Faraday::UnprocessableEntityError)
      end
    end
  end

  describe 'Generic HTTP Error Classes' do
    describe Drasil::ClientError do
      it 'is defined' do
        expect(defined?(Drasil::ClientError)).to eq('constant')
      end

      it 'inherits from Faraday::ClientError' do
        expect(Drasil::ClientError.superclass).to eq(Faraday::ClientError)
      end

      it 'can be raised with a message' do
        expect { raise Drasil::ClientError, 'client error' }.to raise_error(Drasil::ClientError, 'client error')
      end

      it 'is a generic catch-all for 4xx errors' do
        error = Drasil::ClientError.new('test')
        expect(error).to be_a(Faraday::ClientError)
      end
    end

    describe Drasil::ServerError do
      it 'is defined' do
        expect(defined?(Drasil::ServerError)).to eq('constant')
      end

      it 'inherits from Faraday::ServerError' do
        expect(Drasil::ServerError.superclass).to eq(Faraday::ServerError)
      end

      it 'can be raised with a message' do
        expect { raise Drasil::ServerError, 'server error' }.to raise_error(Drasil::ServerError, 'server error')
      end

      it 'is a generic catch-all for 5xx errors' do
        error = Drasil::ServerError.new('test')
        expect(error).to be_a(Faraday::ServerError)
      end
    end
  end

  describe 'Connection Error Classes' do
    describe Drasil::TimeoutError do
      it 'is defined' do
        expect(defined?(Drasil::TimeoutError)).to eq('constant')
      end

      it 'inherits from Faraday::TimeoutError' do
        expect(Drasil::TimeoutError.superclass).to eq(Faraday::TimeoutError)
      end
    end

    describe Drasil::ConnectionFailed do
      it 'is defined' do
        expect(defined?(Drasil::ConnectionFailed)).to eq('constant')
      end

      it 'inherits from Faraday::ConnectionFailed' do
        expect(Drasil::ConnectionFailed.superclass).to eq(Faraday::ConnectionFailed)
      end
    end

    describe Drasil::SSLError do
      it 'is defined' do
        expect(defined?(Drasil::SSLError)).to eq('constant')
      end

      it 'inherits from Faraday::SSLError' do
        expect(Drasil::SSLError.superclass).to eq(Faraday::SSLError)
      end
    end
  end

  describe 'Parser Error Classes' do
    describe Drasil::ParsingError do
      it 'is defined' do
        expect(defined?(Drasil::ParsingError)).to eq('constant')
      end

      it 'inherits from Faraday::ParsingError' do
        expect(Drasil::ParsingError.superclass).to eq(Faraday::ParsingError)
      end
    end

    describe Drasil::NilStatusError do
      it 'is defined' do
        expect(defined?(Drasil::NilStatusError)).to eq('constant')
      end

      it 'inherits from Faraday::NilStatusError' do
        expect(Drasil::NilStatusError.superclass).to eq(Faraday::NilStatusError)
      end
    end
  end
end
