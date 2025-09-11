# frozen_string_literal: true

module Drasil
  module Response
    class RaiseError < Faraday::Response::RaiseError
      def on_complete(env)
        case env[:status]
        when 400
          raise Drasil::BadRequestError, response_values(env)
        when 401
          raise Drasil::UnauthorizedError, response_values(env)
        when 403
          raise Drasil::ForbiddenError, response_values(env)
        when 404
          raise Drasil::ResourceNotFound, response_values(env)
        when 407
          # mimic the behavior that we get with proxy requests with HTTPS
          msg = %(407 "Proxy Authentication Required")
          raise Drasil::ProxyAuthError.new(msg, response_values(env))
        when 408
          raise Drasil::RequestTimeoutError, response_values(env)
        when 409
          raise Drasil::ConflictError, response_values(env)
        when 422
          raise Drasil::UnprocessableEntityError, response_values(env)
        when ClientErrorStatuses
          raise Drasil::ClientError, response_values(env)
        when ServerErrorStatuses
          raise Drasil::ServerError, response_values(env)
        when nil
          raise Drasil::NilStatusError, response_values(env)
        end
      end
    end
  end
end
