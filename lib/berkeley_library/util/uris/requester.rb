require 'rest-client'
require 'berkeley_library/util/uris/appender'
require 'berkeley_library/util/uris/validator'
require 'berkeley_library/logging'

module BerkeleyLibrary
  module Util
    module URIs
      class Requester
        include BerkeleyLibrary::Logging

        # ------------------------------------------------------------
        # Class methods

        class << self
          # Performs a GET request and returns the response body as a string.
          #
          # @param uri [URI, String] the URI to GET
          # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
          # @param headers [Hash] the request headers.
          # @return [String] the body as a string.
          # @param log [Boolean] whether to log each request URL and response code
          # @raise [RestClient::Exception] in the event of an unsuccessful request.
          def get(uri, params: {}, headers: {}, log: true)
            resp = make_request(:get, uri, params, headers, log)
            resp.body
          end

          # Performs a HEAD request and returns the response status as an integer.
          # Note that unlike {Requester#get}, this does not raise an error in the
          # event of an unsuccessful request.
          #
          # @param uri [URI, String] the URI to HEAD
          # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
          # @param headers [Hash] the request headers.
          # @param log [Boolean] whether to log each request URL and response code
          # @return [Integer] the response code as an integer.
          def head(uri, params: {}, headers: {}, log: true)
            head_response(uri, params: params, headers: headers, log: log).code
          end

          # Performs a GET request and returns the response, even in the event of
          # a failed request.
          #
          # @param uri [URI, String] the URI to GET
          # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
          # @param headers [Hash] the request headers.
          # @param log [Boolean] whether to log each request URL and response code
          # @return [RestClient::Response] the body as a string.
          def get_response(uri, params: {}, headers: {}, log: true)
            make_request(:get, uri, params, headers, log)
          rescue RestClient::Exception => e
            e.response
          end

          # Performs a HEAD request and returns the response, even in the event of
          # a failed request.
          #
          # @param uri [URI, String] the URI to HEAD
          # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
          # @param headers [Hash] the request headers.
          # @param log [Boolean] whether to log each request URL and response code
          # @return [RestClient::Response] the response
          def head_response(uri, params: {}, headers: {}, log: true)
            make_request(:head, uri, params, headers, log)
          rescue RestClient::Exception => e
            e.response
          end

          private

          def make_request(method, url, params, headers, log)
            Requester.new(method, url, params: params, headers: headers, log: log).make_request
          end
        end

        # ------------------------------------------------------------
        # Constants

        SUPPORTED_METHODS = %i[get head].freeze

        # ------------------------------------------------------------
        # Attributes

        attr_reader :method, :url_str, :headers, :log

        # ------------------------------------------------------------
        # Initializer

        # Initializes a new Requester.
        #
        # @param method [:get, :head] the HTTP method to use
        # @param url [String, URI] the URL or URI to request
        # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
        # @param headers [Hash] the request headers.
        # @param log [Boolean] whether to log each request URL and response code
        # @raise URI::InvalidURIError if the specified URL is invalid
        def initialize(method, url, params: {}, headers: {}, log: true)
          raise ArgumentError, "#{method} not supported" unless SUPPORTED_METHODS.include?(method)
          raise ArgumentError, 'url cannot be nil' unless (uri = Validator.uri_or_nil(url))

          @method = method
          @url_str = url_str_with_params(uri, params)
          @headers = headers
          @log = log
        end

        # ------------------------------------------------------------
        # Public instance methods

        # @return [RestClient::Response]
        def make_request
          execute_request.tap do |resp|
            log_response(resp)
          end
        rescue RestClient::Exception => e
          log_response(e.response)
          raise
        end

        # ------------------------------------------------------------
        # Private methods

        private

        def log_response(response)
          return unless log

          logger.info("#{method.to_s.upcase} #{url_str} returned #{response.code}")
        end

        def url_str_with_params(uri, params)
          elements = [uri]
          if params.any?
            elements << (uri.query ? '&' : '?')
            elements << URI.encode_www_form(params)
          end

          Appender.new(*elements).to_url_str
        end

        def execute_request
          RestClient::Request.execute(method: method, url: url_str, headers: headers).tap do |response|
            # Not all failed RestClient requests throw exceptions
            raise(exception_for(response)) unless response.code == 200
          end
        end

        def exception_for(resp)
          status = resp.code
          ex_class_for(status).new(resp, status).tap do |ex|
            status_message = RestClient::STATUSES[status] || '(Unknown)'
            ex.message = "#{status} #{status_message}"
          end
        end

        def ex_class_for(status)
          RestClient::Exceptions::EXCEPTIONS_MAP[status] || RestClient::RequestFailed
        end

      end
    end
  end
end
