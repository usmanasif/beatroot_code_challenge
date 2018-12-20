class ReleasesController < ApplicationController
  def index
    @releases = BeatrootApi.fetch_releases
  end

  def download
    response_file = XMLBuilder::ReleaseXML.generate_response_xml_file(params[:id])

    return render_errors if response_file.blank?

    send_file response_file
    ensure
    response_file.close
  end
end
