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
    release_response = HTTParty.get(
      "#{ENV['API_BASE_URL']}/accounts/#{ENV['API_ACCOUNT_SLUG']}/releases/#{params[:id]}",
      headers: { Authorization: "Token token=#{ENV['API_TOKEN']}" }
    )

    release = release_response['release']

    tracks = []
    release['tracks'].each do |track|
      track_response = HTTParty.get(
        "#{ENV['API_BASE_URL']}/accounts/#{ENV['API_ACCOUNT_SLUG']}/tracks/#{track['id']}",
        headers: { Authorization: "Token token=#{ENV['API_TOKEN']}" }
      )

      tracks << track_response['track']
    end

    resource_list_xml = Nokogiri::XML::Builder.new do |xml|
      xml.ResourceList {
        tracks.each do |track|
          xml.Track {
            xml.ISRC track['isrc']
            xml.ResourceReference track['id']
            xml.ReferenceTitle {
              xml.TitleText track['title']
              xml.SubTitle track['subtitle']
            }
            xml.Duration track['duration']
            xml.ArtistName track.dig('artist', 'name')
            xml.LabelName track.dig('record_labels', 0, 'name')
            xml.PLine {
              xml.Year track.dig('record_labels', 0, 'p_line')&.[](0..3)
              xml.PLineText track.dig('record_labels', 0, 'p_line')
            }
            xml.Genre track.dig('tag', 'name') if track.dig('tag', 'classification') == 'genre'
            xml.ParentalWarningType track['parental_warning']&.camelize
          }
        end
      }
    end

    release_xml = Nokogiri::XML::Builder.new do |xml|
      xml.Release {
        xml.ReleaseId {
          xml.GRid release['grid']
          xml.EAN release['ean']
          xml.CatalogNumber release['catalogue_number']
        }
        xml.ReferenceTitle {
          xml.TitleText release['title']
          xml.SubTitle release['subtitle']
        }
        xml.ReleaseResourceReferenceList {
          release['tracks'].each do |track|
            xml.ReleaseResourceReference track['id']
          end
        }
        xml.ProductType release['product_type']
        xml.ArtistName release.dig('artist', 'name')
        xml.ParentalWarningType release['parental_warning']
        xml.ResourceGroup {
          release['tracks'].each do |track|
            xml.ResourceGroupContent {
              xml.SequenceNumber track['position']
              xml.ReleaseResourceReference track['id']
            }
          end
        }
        release['tags'].each do |tag|
          xml.Genre tag['name'] if tag['classification'] == 'genre'
        end
        xml.OriginalReleaseDate release['release_date']
        xml.Duration release['duration']
        xml.PLine {
          xml.Year release.dig('record_labels', 0, 'p_line')&.[](0..3)
          xml.PLineText release.dig('record_labels', 0, 'p_line')
        }
        xml.CLine {
          xml.Year release.dig('record_labels', 0, 'c_line')&.[](0..3)
          xml.CLineText release.dig('record_labels', 0, 'c_line')
        }
      }
    end

    response = resource_list_xml.to_xml.to_s << release_xml.doc.children.to_xml.to_s

    begin
      xml_file = Tempfile.new(release['title'])
      xml_file.write(response)
      send_file xml_file
    ensure
      xml_file.close
    end
  end
end
