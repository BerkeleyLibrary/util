module BerkeleyLibrary
  module Util
    module Files
      class << self
        include Files
      end

      def file_exists?(path)
        (path.respond_to?(:exist?) && path.exist?) ||
          (path.respond_to?(:to_str) && File.exist?(path))
      end

      def parent_exists?(path)
        (path.respond_to?(:parent) && path.parent.exist?) ||
          (path.respond_to?(:to_str) && Pathname.new(path).parent.exist?)
      end

      # Returns true if `obj` is close enough to an IO object for Nokogiri
      # to parse as one.
      #
      # @param obj [Object] the object that might be an IO
      # @see https://github.com/sparklemotion/nokogiri/blob/v1.11.1/lib/nokogiri/xml/sax/parser.rb#L81 Nokogiri::XML::SAX::Parser#parse
      def reader_like?(obj)
        obj.respond_to?(:read) && obj.respond_to?(:close)
      end

      # Returns true if `obj` is close enough to an IO object for Nokogiri
      # to write to.
      #
      # @param obj [Object] the object that might be an IO
      def writer_like?(obj)
        obj.respond_to?(:write) && obj.respond_to?(:close)
      end

    end
  end
end
