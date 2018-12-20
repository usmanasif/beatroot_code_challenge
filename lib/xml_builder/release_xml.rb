module XMLBuilder
  class ReleaseXML < Base
    class << self
      def prepare_xml_data(release_id)
        release = BeatrootApi.fetch_release(release_id)
        tracks = []

        if release['tracks'].present?
          release['tracks'].each do |track|
            response = BeatrootApi.fetch_track(track['id'])
            next if response.blank?

            tracks << response
          end
        end

        { release: release, tracks: tracks } if xml_data_exists?(release, tracks)
      end

      def generate_response_xml_file(id)
        data = prepare_xml_data(id)

        return if data.blank?
        prepare_xml_file(data)
      end

      private
        def prepare_xml_file(data)
          xml_file = Tempfile.new(data[:release]['title'])
          xml_file.write(resource_list_xml(data[:tracks]))
          xml_file.write(release_xml(data[:release]))

          xml_file
        end

        def resource_list_xml(tracks)
          resource_list = Nokogiri::XML::Builder.new do |xml|
            xml.ResourceList do
              tracks.each do |track|
                xml.Track do
                  xml.ISRC track['isrc']
                  xml.ResourceReference track['id']

                  xml.ReferenceTitle do
                    xml.TitleText track['title']
                    xml.SubTitle track['subtitle']
                  end

                  xml.Duration format_duration(track['duration'])
                  xml.ArtistName track.dig('artist', 'name')
                  xml.LabelName track.dig('record_labels', 0, 'name')

                  xml.PLine do
                    xml.Year track.dig('record_labels', 0, 'p_line')&.split&.[](0)
                    xml.PLineText track.dig('record_labels', 0, 'p_line')
                  end

                  xml.Genre track.dig('tag', 'name') if track.dig('tag', 'classification') == 'genre'
                  xml.ParentalWarningType track['parental_warning']&.camelize
                end
              end
            end
          end

          resource_list.to_xml(save_with: default_xml_flags)
        end

        def release_xml(release)
          release = Nokogiri::XML::Builder.new do |xml|
            xml.Release do
              xml.ReleaseId do
                xml.GRid release['grid']
                xml.EAN release['ean']
                xml.CatalogNumber release['catalogue_number']
              end

              xml.ReferenceTitle do
                xml.TitleText release['title']
                xml.SubTitle release['subtitle']
              end

              xml.ReleaseResourceReferenceList do
                release['tracks'].each do |track|
                  xml.ReleaseResourceReference track['id']
                end
              end

              xml.ProductType release['product_type']
              xml.ArtistName release.dig('artist', 'name')
              xml.ParentalWarningType release['parental_warning']&.camelize

              xml.ResourceGroup do
                release['tracks'].each do |track|
                  xml.ResourceGroupContent do
                    xml.SequenceNumber track['position']
                    xml.ReleaseResourceReference track['id']
                  end
                end
              end

              release['tags'].each do |tag|
                xml.Genre tag['name'] if tag['classification'] == 'genre'
              end

              xml.OriginalReleaseDate release['release_date']
              xml.Duration format_duration(release['duration'])

              xml.PLine do
                xml.Year release.dig('record_labels', 0, 'p_line')&.split&.[](0)
                xml.PLineText release.dig('record_labels', 0, 'p_line')
              end

              xml.CLine do
                xml.Year release.dig('record_labels', 0, 'c_line')&.split&.[](0)
                xml.CLineText release.dig('record_labels', 0, 'c_line')
              end
            end
          end

          release.doc.children.to_xml(save_with: default_xml_flags)
        end

        def xml_data_exists?(release, tracks)
          release.present? && tracks.present?
        end

        def format_duration(duration_in_seconds)
          duration_parts = ActiveSupport::Duration.build(duration_in_seconds).parts
          hours = '%02d' % duration_parts[:hours]
          minutes = '%02d' % duration_parts[:minutes]
          seconds = '%02d' % duration_parts[:seconds]

          beautify_duration(hours, minutes, seconds)
        end

        def beautify_duration(hours, minutes, seconds)
          "PT#{hours}H#{minutes}M#{seconds}S"
        end
    end
  end
end
