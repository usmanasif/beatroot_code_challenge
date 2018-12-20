class BeatrootApi
  API_BASE_URL = ENV['API_BASE_URL']
  ACCOUNT_SLUG = ENV['API_ACCOUNT_SLUG']
  API_TOKEN = ENV['API_TOKEN']
  USER_BASE_URL = "#{API_BASE_URL}/accounts/#{ACCOUNT_SLUG}".freeze

  class << self
    def fetch_releases
      response =  get(releases_path)
      response.present? && response['releases'] || []
    end

    def fetch_release(id)
      response = get(release_path(id))
      response.present? && response['release'] || {}
    end

    def fetch_track(id)
      response = get(track_path(id))
      response.present? && response['track'] || {}
    end

    private
      def get(url)
        response = HTTParty.get([USER_BASE_URL, url].join, headers: auth_headers)
        handle_response(response)
      rescue HTTParty::Error, SocketError => error
        puts error
      end

      def handle_response(response)
        case response.code
          when 200..201
            response
          when 401
            puts "Invalid Token: #{response.message}"
          else
            puts "Failed Request: #{response.code}, #{response.message}"
        end
      end

      def auth_headers
        { Authorization: "Token token=#{API_TOKEN}" }
      end

      def releases_path
        '/releases'
      end

      def release_path(id)
        "/releases/#{id}"
      end

      def track_path(id)
        "/tracks/#{id}"
      end
  end
end
