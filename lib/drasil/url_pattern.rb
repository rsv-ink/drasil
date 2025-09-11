module Drasil
  class UrlPattern
    def initialize(url_pattern)
      pattern = url_pattern.gsub("/", "\\/")
      pattern = pattern.gsub(/:[a-zA-Z0-9_-]+/, ".*")
      @regex  = Regexp.new(pattern)
    end

    def match?(value)
      @regex.match?(value)
    end
  end
end
