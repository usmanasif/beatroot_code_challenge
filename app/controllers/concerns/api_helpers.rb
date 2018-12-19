module ApiHelpers
  extend ActiveSupport::Concern

  def api_get_request(url)
    HTTParty.get(
      "#{ENV['API_BASE_URL']}/accounts/#{ENV['API_ACCOUNT_SLUG']}" << url,
      headers: { Authorization: "Token token=#{ENV['API_TOKEN']}" })
  end
end
