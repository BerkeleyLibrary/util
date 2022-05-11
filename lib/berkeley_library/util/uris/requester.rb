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

          # Performs a GET request and returns the response body as a string.
          #
          # @param uri [URI, String] the URI to GET
          # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
          # @param headers [Hash] the request headers.
          # @return [String] the body as a string.
          # @raise [RestClient::Exception] in the event of an error.
          def get(uri, params: {}, headers: {})
            resp = make_get_request(uri, params, headers)
            resp.body
          end

          # Performs a GET request and returns the response.
          #
          # @param uri [URI, String] the URI to GET
          # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
          # @param headers [Hash] the request headers.
          # @return [RestClient::Response] the body as a string.
          def get_response(uri, params: {}, headers: {})
            make_get_request(uri, params, headers)
          rescue RestClient::Exception => e
            e.response
          end

          private

          def make_get_request(uri, params, headers)
            url_str = url_str_with_params(uri, params)
            get_or_raise(url_str, headers)
          end

          def url_str_with_params(uri, params)
            raise ArgumentError, 'uri cannot be nil' unless (url_str = Validator.url_str_or_nil(uri))

            elements = [].tap do |ee|
              ee << url_str
              next if params.empty?

              ee << '?' unless url_str.include?('?')
              ee << URI.encode_www_form(params)
            end

            uri = Appender.new(*elements).to_uri
            uri.to_s
          end

          # @return [RestClient::Response]
          def get_or_raise(url_str, headers)
            resp = RestClient.get(url_str, headers)
            begin
              return resp if (status = resp.code) == 200

              raise(exception_for(resp, status))
            ensure
              # noinspection RubyMismatchedReturnType
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
