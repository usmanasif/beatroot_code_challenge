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

    builder = Nokogiri::XML::Builder.new do |xml|
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
            xml.ArtistName track['artist']['name']
            xml.LabelName track['record_labels'][0]['name']
            xml.PLine {
              xml.Year track['record_labels'][0]['p_line'][0..3]
              xml.PLineText track['record_labels'][0]['p_line']
            }
            xml.Genre track['tag']['name'] if track['tag']['classification'] == 'genre'
            xml.ParentalWarningType track['parental_warning'].camelize
          }
        end
      }
    end

    builder2 = Nokogiri::XML::Builder.new do |xml|
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
        xml.ArtistName release['artist']['name']
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
          xml.Genre tag['name'] if classification['genre']
        end
        xml.OriginalReleaseDate release['release_date']
      }
    end

    puts builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_EMPTY_TAGS)

    response = builder.to_xml.to_s << builder2.to_xml.to_s
    render xml: response
  end
end
