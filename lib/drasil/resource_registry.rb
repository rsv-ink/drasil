# frozen_string_literal: true

module Drasil
  # Registry for managing resources associated with a client
  #
  # The ResourceRegistry allows dynamic registration of resource classes
  # and creates scoped versions of these classes that are bound to a
  # specific client instance. This enables multiple clients to use the
  # same resource classes with different configurations and connections.
  #
  # @example Basic usage
  #   registry = ResourceRegistry.new(client)
  #   registry.register(:sellers, Seller, parser: SellerParser)
  #   registry.get(:sellers) #=> Scoped Seller class bound to client
  #
  # @example Checking registration
  #   registry.registered?(:sellers) #=> true
  #   registry.registered?(:unknown) #=> false
  class ResourceRegistry
    # Creates a new ResourceRegistry instance
    #
    # @param client [Drasil::Client] The client this registry belongs to
    def initialize(client)
      @client = client
      @resources = {}
    end

    # Registers a resource with the registry
    #
    # Creates a scoped version of the resource class that is bound to
    # this registry's client. If a parser is provided, it will be
    # registered with the client's configuration.
    #
    # @param name [Symbol] The name to register the resource under
    # @param resource_class [Class] The resource class (should inherit from Drasil::Base)
    # @param parser [Class, nil] Optional parser class to register for this resource
    # @param parser_path [String, nil] Optional URL pattern for the parser
    # @return [Class] The scoped resource class
    #
    # @example Without parser
    #   registry.register(:sellers, Seller)
    #
    # @example With parser
    #   registry.register(:sellers, Seller, parser: SellerParser, parser_path: "/sellers/*")
    def register(name, resource_class, parser: nil, parser_path: nil)
      # Register parser if provided
      if parser && parser_path
        @client.config.add_parser(parser_path, parser)
      end

      # Create a new class that inherits from the resource class
      # and is bound to this client
      scoped_class = create_scoped_class(resource_class)

      # Store the scoped class in the registry
      @resources[name] = scoped_class

      scoped_class
    end

    # Retrieves a registered resource
    #
    # @param name [Symbol] The name of the resource to retrieve
    # @return [Class] The scoped resource class
    # @raise [ResourceNotFoundError] if the resource is not registered
    #
    # @example
    #   sellers_class = registry.get(:sellers)
    #   seller = sellers_class.find("123")
    def get(name)
      @resources[name] || raise(
        ResourceNotFoundError,
        "Resource '#{name}' not found in registry. " \
        "Available resources: #{@resources.keys.join(', ')}"
      )
    end

    # Checks if a resource is registered
    #
    # @param name [Symbol] The name of the resource to check
    # @return [Boolean] true if registered, false otherwise
    #
    # @example
    #   registry.registered?(:sellers) #=> true
    #   registry.registered?(:unknown) #=> false
    def registered?(name)
      @resources.key?(name)
    end

    # Returns all registered resource names
    #
    # @return [Array<Symbol>] List of registered resource names
    #
    # @example
    #   registry.resource_names #=> [:sellers, :buyers, :transactions]
    def resource_names
      @resources.keys
    end

    private

    # Creates a scoped class that inherits from the resource class
    # and overrides connection and configuration to use this client
    #
    # @param resource_class [Class] The base resource class
    # @return [Class] A new class bound to this client
    def create_scoped_class(resource_class)
      client = @client

      Class.new(resource_class) do
        # Define a name method for Spyke
        define_singleton_method(:name) do
          resource_class.name
        end

        # Store reference to client
        @_drasil_client = client

        # Override class methods to use this client
        class << self
          attr_accessor :_drasil_client

          def drasil_client
            @_drasil_client
          end

          def drasil_client=(value)
            @_drasil_client = value
          end

          def connection
            @_drasil_client ? @_drasil_client.connection : super
          end
        end

        # Set the client
        self._drasil_client = client
      end
    end
  end
end
