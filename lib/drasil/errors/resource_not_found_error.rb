# frozen_string_literal: true

module Drasil
  # Raised when a resource is not found in the registry
  #
  # @example
  #   raise ResourceNotFoundError, "Resource 'sellers' not found in registry"
  class ResourceNotFoundError < StandardError
  end
end
