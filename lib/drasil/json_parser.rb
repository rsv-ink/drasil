module Drasil
  class JSONParser < Faraday::Middleware
    def on_complete(env)
      json = MultiJson.load(env.body, symbolize_keys: true)

      data, metadata = Config.parse(env.url.to_s, json)

      env.body = {
        data: data,
        metadata: metadata,
        errors: []
      }
    end

    private
      def error?(http_status)
        !http_status.to_s.start_with?("2")
      end
  end
end
