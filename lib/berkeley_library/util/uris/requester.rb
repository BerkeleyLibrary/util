require 'rest-client'
require 'berkeley_library/util/uris/appender'
require 'berkeley_library/util/uris/validator'
require 'berkeley_library/logging'

module BerkeleyLibrary
  module Util
    module URIs
      module Requester
        class << self
          include BerkeleyLibrary::Logging

          # Performs a GET request.
          #
          # @param uri [URI, String] the URI to GET
          # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
          # @param headers [Hash] the request headers.
          # @return [String] the body as a string.
          # @raise [RestClient::Exception] in the event of an error.
          def get(uri, params = {}, headers = {})
            url_str = url_str_with_params(uri, params)
            resp = get_or_raise(url_str, headers)
            resp.body
          end

          private

          def url_str_with_params(uri, params)
            raise ArgumentError, 'uri cannot be nil' unless (url_str = Validator.url_str_or_nil(uri))

            elements = [].tap do |ee|
              ee << url_str
              ee << '?' unless url_str.include?('?')
              ee << URI.encode_www_form(params)
            end

            uri = Appender.new(*elements).to_uri
            uri.to_s
          end

          def get_or_raise(url_str, headers)
            resp = RestClient.get(url_str, headers)
            begin
              return resp if (status = resp.code) == 200

              raise(exception_for(resp, status))
            ensure
              logger.info("GET #{url_str} returned #{status}")
            end
          end

          def exception_for(resp, status)
            RestClient::RequestFailed.new(resp, status).tap do |ex|
              status_message = RestClient::STATUSES[status] || '(Unknown)'
              ex.message = "#{status} #{status_message}"
            end
          end
        end
      end
    end
  end
end
