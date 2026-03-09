# frozen_string_literal: true

module Drasil
  # Wrapper class that delegates to a resource class with a specific client
  #
  # This class acts as a transparent proxy to a Drasil::Base subclass,
  # ensuring all method calls use the correct client instance.
  class ResourceWrapper < BasicObject
    def initialize(resource_class, client)
      @resource_class = resource_class
      @client = client
    end

    def method_missing(method, *args, &block)
      # Temporarily set the client on the class
      previous_client = @resource_class.drasil_client
      @resource_class.drasil_client = @client

      begin
        @resource_class.public_send(method, *args, &block)
      ensure
        # Restore previous client
        @resource_class.drasil_client = previous_client
      end
    end

    def respond_to_missing?(method, include_private = false)
      @resource_class.respond_to?(method, include_private)
    end

    # Delegate class methods
    def class
      @resource_class
    end

    def is_a?(klass)
      @resource_class <= klass
    end

    def kind_of?(klass)
      is_a?(klass)
    end
  end
end
