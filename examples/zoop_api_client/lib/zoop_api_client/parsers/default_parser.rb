module ZoopApiClient
  module Parsers
    class DefaultParser < Drasil::Parser
      def parse
        data     = @response
        metadata = {}

        [data, metadata]
      end
    end
  end
end
