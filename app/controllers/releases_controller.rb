class ReleasesController < ApplicationController
  def index
    response = HTTParty.get(
      "#{ENV['API_BASE_URL']}/accounts/#{ENV['API_ACCOUNT_SLUG']}/releases",
      headers: { Authorization: "Token token=#{ENV['API_TOKEN']}" }
    )

    @releases = if response.success? && response['releases'].present?
      response['releases']
    else
      []
    end
  end

  def download
  end
end
