module XMLBuilder
  class Base
    class << self
      protected
        def default_xml_flags
          Nokogiri::XML::Node::SaveOptions::NO_EMPTY_TAGS | Nokogiri::XML::Node::SaveOptions::FORMAT
        end
    end
  end
end
