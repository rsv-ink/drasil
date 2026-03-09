# frozen_string_literal: true

module Drasil
  # Raised when no parser is found for a given URL pattern
  #
  # @example
  #   raise ParserNotFoundError, "No parser found for URL: /unknown/path"
  class ParserNotFoundError < StandardError
  end
end
