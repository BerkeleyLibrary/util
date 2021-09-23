require 'uri'

module BerkeleyLibrary
  module Util
    module URIs
      module Validator
        class << self

          # Returns the specified URL as a URI.
          # @param url [String, URI] the URL.
          # @return [URI] the URI.
          # @raise [URI::InvalidURIError] if `url` cannot be parsed as a URI.
          def uri_or_nil(url)
            return unless url

            # noinspection RubyYardReturnMatch
            url.is_a?(URI) ? url : URI.parse(url.to_s)
          end

          # Returns the specified URL as a string.
          # @param url [String, URI] the URL.
          # @return [String] the URL.
          # @raise [URI::InvalidURIError] if `url` cannot be parsed as a URI.
          def url_str_or_nil(url)
            uri = Validator.uri_or_nil(url)
            uri.to_s if uri
          end
        end
      end
    end
  end
end
