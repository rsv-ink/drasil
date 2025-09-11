module Drasil
  class Parser
    def initialize(response)
      @response = response
    end

    def parse
      raise NotImplementedError
    end
  end
end
