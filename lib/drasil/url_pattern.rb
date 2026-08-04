# frozen_string_literal: true

module Drasil
  # Translates a URL pattern into a regular expression used to route responses
  # to their parser.
  #
  # Patterns are globs, not regular expressions:
  #
  #   :param        matches a single path segment  ("/users/:id" -> "/users/1")
  #   *             matches a single path segment  ("/users/*/posts")
  #   /*  (at end)  matches an optional segment    ("/users/*" -> "/users" and "/users/1")
  #   **            matches the remaining path     ("/users/**")
  #
  # Matching runs against the *path* of the URL (scheme, host, query string and
  # fragment are ignored) and both ends are anchored at a segment boundary, so
  # "/users/*" matches "/v1/users/1" but not "/usersXYZ" nor "/admin/users_backup".
  #
  # A pattern ending in "/" keeps the historical prefix behaviour: it matches any
  # deeper path ("/sellers/:id/" matches "/sellers/1/balances/").
  #
  # @example
  #   pattern = Drasil::UrlPattern.new("/sellers/:id")
  #   pattern.match?("https://api.example.com/v1/sellers/123?full=true") #=> true
  #   pattern.match?("https://api.example.com/sellers_archive/123")      #=> false
  class UrlPattern
    # Matches a pattern token: "**", "*" or ":param"
    TOKEN = /\A(\*\*|\*|:[a-zA-Z0-9_-]+)/

    # @param url_pattern [String] The URL pattern to compile
    # @raise [ArgumentError] if the pattern is blank
    # @raise [RegexpError] if the pattern is not a valid pattern
    def initialize(url_pattern)
      raise ArgumentError, 'URL pattern cannot be blank' if url_pattern.blank?

      @url_pattern = url_pattern.to_s

      validate!

      @regex = Regexp.new("(?:\\A|/)#{translate}")
    end

    # @param value [String, nil] A full URL or a bare path
    # @return [Boolean] true when the value's path matches this pattern
    def match?(value)
      return false if value.nil?

      @regex.match?(path_of(value))
    end

    private

    # Rejects malformed patterns.
    #
    # Drasil has always surfaced RegexpError for malformed patterns (e.g. "?["),
    # so that contract is preserved even though patterns are now translated. The
    # glob wildcard is stripped first: "*" is a Drasil token, not a quantifier,
    # and compiling it as one makes Ruby warn about redundant repeat operators.
    #
    # @raise [RegexpError]
    def validate!
      Regexp.new(@url_pattern.delete('*'))
    end

    # Compiles the pattern into a regular expression source string
    #
    # @return [String]
    def translate
      pattern = @url_pattern
      optional_tail = false

      # A trailing "/*" means "an optional last segment", so a collection
      # endpoint ("/users") is matched by the same pattern as its members
      # ("/users/1").
      if pattern.end_with?('/*') && !pattern.end_with?('/**')
        pattern = pattern[0..-3]
        optional_tail = true
      end

      # The leading separator is already expressed by the "(?:\A|/)" boundary
      open_ended = pattern.end_with?('/', '**')
      pattern = pattern.sub(%r{\A/}, '')

      source = +''
      rest = pattern.dup

      until rest.empty?
        if (token = rest[TOKEN, 1])
          source << (token == '**' ? '.*' : '[^/]+')
          rest = rest[token.length..]
        else
          source << Regexp.escape(rest[0])
          rest = rest[1..]
        end
      end

      source << '(?:/[^/]*)?' if optional_tail

      # Close the match on a segment boundary, unless the pattern explicitly
      # opted into prefix matching by ending in "/" or "**".
      source << '(?=/|\z)' unless open_ended

      source
    end

    # Extracts the path from a full URL, dropping query string and fragment
    #
    # @param value [String] A full URL or a bare path
    # @return [String]
    def path_of(value)
      value.to_s
           .sub(%r{\A[a-zA-Z][a-zA-Z0-9+.\-]*://[^/]*}, '')
           .sub(/[?#].*\z/, '')
    end
  end
end
