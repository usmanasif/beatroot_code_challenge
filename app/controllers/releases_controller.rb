class ReleasesController < ApplicationController
  include ApiHelpers
  include XMLBuilder

  def index
    response = api_get_request("/releases")

    @releases = if response.success? && response['releases'].present?
      response['releases']
    else
      []
    end
  end

  def download
    release_response = api_get_request("/releases/#{params[:id]}")
    release = release_response['release']
    tracks = []

    release['tracks'].each do |track|
      track_response = api_get_request("/tracks/#{track['id']}")
      tracks << track_response['track']
    end

    response = generate_response_xml(release, tracks)

    begin
      xml_file = Tempfile.new(release['title'])
      xml_file.write(response)
      send_file xml_file
    ensure
      xml_file.close
    end
  end
end
