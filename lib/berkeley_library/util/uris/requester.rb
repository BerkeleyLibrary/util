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
          # @raise [RestClient::Exception] in the event of an unsuccessful request.
          def get(uri, params: {}, headers: {})
            resp = make_request(:get, uri, params, headers)
            resp.body
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
            head_response(uri, params: params, headers: headers).code
          end

          # Performs a GET request and returns the response, even in the event of
          # a failed request.
          #
          # @param uri [URI, String] the URI to GET
          # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
          # @param headers [Hash] the request headers.
          # @return [RestClient::Response] the body as a string.
          def get_response(uri, params: {}, headers: {})
            make_request(:get, uri, params, headers)
          rescue RestClient::Exception => e
            e.response
          end

          # Performs a HEAD request and returns the response, even in the event of
          # a failed request.
          #
          # @param uri [URI, String] the URI to HEAD
          # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
          # @param headers [Hash] the request headers.
          # @return [RestClient::Response] the body as a string.
          def head_response(uri, params: {}, headers: {})
            make_request(:head, uri, params, headers)
          rescue RestClient::Exception => e
            e.response
          end

          private

          # @return [RestClient::Response]
          def make_request(method, uri, params, headers)
            url_str = url_str_with_params(uri, params)
            req_resp_or_raise(method, url_str, headers)
          end

          def url_str_with_params(url, params)
            raise ArgumentError, 'url cannot be nil' unless (uri = Validator.uri_or_nil(url))

            elements = [].tap do |ee|
              ee << uri
              next if params.empty?

              ee << (uri.query ? '&' : '?')
              ee << URI.encode_www_form(params)
            end

            uri = Appender.new(*elements).to_uri
            uri.to_s
          end

          # @return [RestClient::Response]
          def req_resp_or_raise(method, url_str, headers)
            resp = RestClient::Request.execute(method: method, url: url_str, headers: headers)
            begin
              return resp if (status = resp.code) == 200

              raise(exception_for(resp, status))
            ensure
              # noinspection RubyMismatchedReturnType
              logger.info("#{method.to_s.upcase} #{url_str} returned #{status}")
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
