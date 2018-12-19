require "rails_helper"

RSpec.describe 'API Connection', type: :request do
  it 'should return 200 response code' do
    base_url_response = HTTParty.get(ENV['API_BASE_URL'])
    expect(base_url_response.code).to eq(200), 'Request URI unreachable'
  end
end

RSpec.describe 'Releases Request', type: :request do
  it 'should authenticate and return releases' do
    releases_response = HTTParty.get("#{ENV['API_BASE_URL']}/accounts/#{ENV['API_ACCOUNT_SLUG']}/releases",
      headers: { Authorization: "Token token=#{ENV['API_TOKEN']}" }
    )
    expect(releases_response.code).to eq(200), 'Invalid Credentials'
    expect(releases_response).to have_key('releases'), 'Response did not contain Releases'
  end
end
