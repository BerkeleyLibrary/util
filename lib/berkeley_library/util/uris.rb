require 'berkeley_library/util/uris/appender'
require 'berkeley_library/util/uris/requester'
require 'berkeley_library/util/uris/validator'

module BerkeleyLibrary
  module Util
    module URIs
      class << self
        include URIs
      end

      # Appends the specified paths to the path of the specified URI, removing any extraneous slashes
      # and merging additional query parameters, and returns a new URI with that path and the same scheme,
      # host, query, fragment, etc. as the original.
      #
      # @param uri [URI, String] the original URI
      # @param elements [Array<String, Symbol>] the URI elements to join.
      # @return [URI] a new URI appending the joined path elements.
      # @raise URI::InvalidComponentError if appending the specified elements would create an invalid URI
      def append(uri, *elements)
        Appender.new(uri, *elements).to_uri
      end

      # Performs a GET request.
      #
      # @param uri [URI, String] the URI to GET
      # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
      # @param headers [Hash] the request headers.
      # @return [String] the body as a string.
      # @raise [RestClient::Exception] in the event of an error.
      def get(uri, params = {}, headers = {})
        Requester.get(uri, params, headers)
      end

      # Returns the specified URL as a URI.
      # @param url [String, URI] the URL.
      # @return [URI] the URI.
      # @raise [URI::InvalidURIError] if `url` cannot be parsed as a URI.
      def uri_or_nil(url)
        Validator.uri_or_nil(url)
      end
    end
  end
end
