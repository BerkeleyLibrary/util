require 'berkeley_library/logging'
require 'berkeley_library/util/uris/appender'
require 'berkeley_library/util/uris/requester'
require 'berkeley_library/util/uris/validator'

module BerkeleyLibrary
  module Util
    module URIs
      include BerkeleyLibrary::Logging

      UTF_8 = Encoding::UTF_8

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

      # Performs a GET request and returns the response body as a string.
      #
      # @param uri [URI, String] the URI to GET
      # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
      # @param headers [Hash] the request headers.
      # @return [String] the body as a string.
      # @raise [RestClient::Exception] in the event of an unsuccessful request.
      def get(uri, params: {}, headers: {})
        Requester.get(uri, params: params, headers: headers)
      end

      # Performs a HEAD request and returns the response status as an integer.
      # Note that unlike {Requester#get}, this does not raise an error in the
      # event of an unsuccessful request.
      #
      # @param uri [URI, String] the URI to HEAD
      # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
      # @param headers [Hash] the request headers.
      # @return [Integer] the response code as an integer.
      def head(uri, params: {}, headers: {})
        Requester.head(uri, params: params, headers: headers)
      end

      # Performs a GET request and returns the response, even in the event of
      # a failed request.
      #
      # @param uri [URI, String] the URI to GET
      # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
      # @param headers [Hash] the request headers.
      # @return [RestClient::Response] the body as a string.
      def get_response(uri, params: {}, headers: {})
        Requester.get_response(uri, params: params, headers: headers)
      end

      # Performs a HEAD request and returns the response, even in the event of
      # a failed request.
      #
      # @param uri [URI, String] the URI to HEAD
      # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
      # @param headers [Hash] the request headers.
      # @return [RestClient::Response] the body as a string.
      def head_response(uri, params: {}, headers: {})
        Requester.head_response(uri, params: params, headers: headers)
      end

      # Returns the specified URL as a URI, or `nil` if the URL is `nil`.
      # @param url [String, URI, nil] the URL.
      # @return [URI] the URI, or `nil`.
      # @raise [URI::InvalidURIError] if `url` is not `nil` and cannot be
      #   parsed as a URI.
      def uri_or_nil(url)
        Validator.uri_or_nil(url)
      end

      # Escapes the specified string so that it can be used as a URL path segment,
      # replacing disallowed characters (including /) with percent-encodings as needed.
      def path_escape(s)
        raise ArgumentError, "Can't escape #{s.inspect}: not a string" unless s.respond_to?(:encoding)
        raise ArgumentError, "Can't escape #{s.inspect}: expected #{UTF_8}, was #{s.encoding}" unless s.encoding == UTF_8

        ''.tap do |escaped|
          s.bytes.each do |b|
            escaped << (should_escape?(b, :path_segment) ? '%%%02X' % b : b.chr)
          end
        end
      end

      # Returns the specified URL as a URI, or `nil` if the URL cannot
      # be parsed.
      # @param url [Object, nil] the URL.
      # @return [URI, nil] the URI, or `nil`.
      def safe_parse_uri(url)
        # noinspection RubyMismatchedArgumentType
        uri_or_nil(url)
      rescue URI::InvalidURIError => e
        logger.warn("Error parsing URL #{url.inspect}", e)
        nil
      end

      private

      # TODO: extend to cover other modes - host, zone, path, password, query, fragment
      #       cf. https://github.com/golang/go/blob/master/src/net/url/url.go
      ALLOWED_BYTES_BY_MODE = {
        path_segment: [0x24, 0x26, 0x2b, 0x3a, 0x3d, 0x40] # @ & = + $
      }.freeze

      def should_escape?(b, mode)
        return false if unreserved?(b)
        return false if ALLOWED_BYTES_BY_MODE[mode]&.include?(b)

        true
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def unreserved?(byte)
        return true if byte >= 0x41 && byte <= 0x5a # A-Z
        return true if byte >= 0x61 && byte <= 0x7a # a-z
        return true if byte >= 0x30 && byte <= 0x39 # 0-9
        return true if [0x2d, 0x2e, 0x5f, 0x7e].include?(byte) # - . _ ~

        false
      end
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
