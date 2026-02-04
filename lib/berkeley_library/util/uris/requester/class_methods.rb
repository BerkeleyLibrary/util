module BerkeleyLibrary
  module Util
    module URIs
      class Requester
        # rubocop:disable Metrics/ParameterLists
        module ClassMethods
          # Performs a GET request and returns the response body as a string.
          #
          # @param uri [URI, String] the URI to GET
          # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
          # @param headers [Hash] the request headers.
          # @return [String] the body as a string.
          # @param log [Boolean] whether to log each request URL and response code
          # @param max_retries [Integer] the maximum number of times to retry after a 429 or 503 with Retry-After
          # @param max_retry_delay [Integer] the maximum retry delay (in seconds) to accept in a Retry-After header
          # @param timeout [Integer] the request timeout in seconds (RestClient will use this to set both open and read timeouts)
          # @raise [RestClient::Exception] in the event of an unsuccessful request.
          def get(uri, params: {}, headers: {}, log: true, max_retries: MAX_RETRIES, max_retry_delay: MAX_RETRY_DELAY_SECONDS,
                  timeout: DEFAULT_TIMEOUT_SECONDS)
            resp = make_request(:get, uri, params, headers, log, max_retries, max_retry_delay, timeout)
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
          def head(uri, params: {}, headers: {}, log: true, max_retries: MAX_RETRIES, max_retry_delay: MAX_RETRY_DELAY_SECONDS,
                   timeout: DEFAULT_TIMEOUT_SECONDS)
            head_response(uri, params: params, headers: headers, log: log, max_retries: max_retries, max_retry_delay: max_retry_delay,
                               timeout: timeout).code
          end

          # Performs a GET request and returns the response, even in the event of
          # a failed request.
          #
          # @param uri [URI, String] the URI to GET
          # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
          # @param headers [Hash] the request headers.
          # @param log [Boolean] whether to log each request URL and response code
          # @return [RestClient::Response] the response
          def get_response(uri, params: {}, headers: {}, log: true, max_retries: MAX_RETRIES, max_retry_delay: MAX_RETRY_DELAY_SECONDS,
                           timeout: DEFAULT_TIMEOUT_SECONDS)
            make_request(:get, uri, params, headers, log, max_retries, max_retry_delay, timeout)
          rescue RestClient::Exception => e
            return e.response if e.response

            raise
          end

          # Performs a HEAD request and returns the response, even in the event of
          # a failed request.
          #
          # @param uri [URI, String] the URI to HEAD
          # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
          # @param headers [Hash] the request headers.
          # @param log [Boolean] whether to log each request URL and response code
          # @return [RestClient::Response] the response
          def head_response(uri, params: {}, headers: {}, log: true, max_retries: MAX_RETRIES, max_retry_delay: MAX_RETRY_DELAY_SECONDS,
                            timeout: DEFAULT_TIMEOUT_SECONDS)
            make_request(:head, uri, params, headers, log, max_retries, max_retry_delay, timeout)
          rescue RestClient::Exception => e
            return e.response if e.response

            raise
          end

          private

          def make_request(method, url, params, headers, log, max_retries, max_retry_delay, timeout)
            Requester.new(
              method,
              url,
              params: params,
              headers: headers,
              log: log,
              max_retries: max_retries,
              max_retry_delay: max_retry_delay,
              timeout: timeout
            ).make_request
          end

        end
        # rubocop:enable Metrics/ParameterLists

        # ------------------------------------------------------------
        # Class methods

        class << self
          include ClassMethods
        end
      end
    end
  end
end
