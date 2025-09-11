# frozen_string_literal: true

module Drasil
  # Raised by Faraday::Response::RaiseError in case of a 400 response.
  class BadRequestError < Faraday::BadRequestError
  end

  # Raised by Faraday::Response::RaiseError in case of a 401 response.
  class UnauthorizedError < Faraday::UnauthorizedError
  end

  # Raised by Faraday::Response::RaiseError in case of a 403 response.
  class ForbiddenError < Faraday::ForbiddenError
  end

  # Raised by Faraday::Response::RaiseError in case of a 404 response.
  class ResourceNotFound < Faraday::ResourceNotFound
  end

  # Raised by Faraday::Response::RaiseError in case of a 407 response.
  class ProxyAuthError < Faraday::ProxyAuthError
  end

  # Raised by Faraday::Response::RaiseError in case of a 408 response.
  class RequestTimeoutError < Faraday::RequestTimeoutError
  end

  # Raised by Faraday::Response::RaiseError in case of a 409 response.
  class ConflictError < Faraday::ConflictError
  end

  # Raised by Faraday::Response::RaiseError in case of a 422 response.
  class UnprocessableEntityError < Faraday::UnprocessableEntityError
  end

  # A unified client error for timeouts.
  class TimeoutError < Faraday::TimeoutError
  end

  # Raised by Faraday::Response::RaiseError in case of a nil status in response.
  class NilStatusError < Faraday::NilStatusError
  end

  # A unified error for failed connections.
  class ConnectionFailed < Faraday::ConnectionFailed
  end

  # A unified client error for SSL errors.
  class SSLError < Faraday::SSLError
  end

  # Raised by middlewares that parse the response, like the JSON response middleware.
  class ParsingError < Faraday::ParsingError
  end
end
