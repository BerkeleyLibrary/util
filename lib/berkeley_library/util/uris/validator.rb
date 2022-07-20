require 'uri'

module BerkeleyLibrary
  module Util
    module URIs
      module Validator
        class << self

          # Returns the specified URL as a URI, or `nil` if the URI is `nil`.
          # @param url [String, URI, nil] the URL.
          # @return [URI] the URI, or `nil`.
          # @raise [URI::InvalidURIError] if `url` is not `nil` and cannot be
          #   parsed as a URI.
          def uri_or_nil(url)
            return unless url

            # noinspection RubyMismatchedReturnType
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
