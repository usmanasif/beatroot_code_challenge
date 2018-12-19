module XMLBuilder
  extend ActiveSupport::Concerns

  def generate_response_xml(release, tracks)
    resource_list_xml = build_resource_list_xml(tracks)
    release_xml = build_release_xml(release)

    resource_list_xml.to_xml.to_s << release_xml.doc.children.to_xml.to_s
  end

  private
    def build_resource_list_xml(tracks)
      Nokogiri::XML::Builder.new do |xml|
        xml.ResourceList {
          tracks.each do |track|
            xml.Track {
              xml.ISRC track['isrc']
              xml.ResourceReference track['id']
              xml.ReferenceTitle {
                xml.TitleText track['title']
                xml.SubTitle track['subtitle']
              }
              xml.Duration format_duration(track['duration'])
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
    end

    def build_release_xml(release)
      Nokogiri::XML::Builder.new do |xml|
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
          xml.Duration format_duration(release['duration'])
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
    end

    def format_duration(duration_in_seconds)
      duration_parts = ActiveSupport::Duration.build(duration_in_seconds).parts
      hours = sprintf '%02d', duration_parts[:hours]
      minutes = sprintf '%02d', duration_parts[:minutes]
      seconds = sprintf '%02d', duration_parts[:seconds]

      "PT#{hours}H#{minutes}M#{seconds}S"
    end
end
