module Drasil
  class UrlMatcher
    def initialize(url, url_pattern)
      @url = url
      @url_pattern = url_pattern
    end

    def match?
      return false if @url.blank? || @url_pattern.blank?

      pattern = UrlPattern.new(@url_pattern)
      pattern.match?(@url)
    rescue RegexpError
      false
    end
  end
end
