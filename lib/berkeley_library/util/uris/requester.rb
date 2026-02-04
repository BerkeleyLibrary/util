require 'time'
require 'rest-client'
require 'berkeley_library/util/uris/appender'
require 'berkeley_library/util/uris/exceptions'
require 'berkeley_library/util/uris/validator'
require 'berkeley_library/util/uris/requester/class_methods'
require 'berkeley_library/logging'

module BerkeleyLibrary
  module Util
    module URIs
      class Requester
        include BerkeleyLibrary::Logging

        # ------------------------------------------------------------
        # Constants

        SUPPORTED_METHODS = %i[get head].freeze
        RETRY_HEADER = :retry_after
        RETRY_STATUSES = [429, 503].freeze
        MAX_RETRY_DELAY_SECONDS = 10
        MAX_RETRIES = 3
        DEFAULT_TIMEOUT_SECONDS = 10

        # ------------------------------------------------------------
        # Attributes

        attr_reader :method, :url_str, :headers, :log, :max_retries, :max_retry_delay, :timeout

        # ------------------------------------------------------------
        # Initializer

        # Initializes a new Requester.
        #
        # @param method [:get, :head] the HTTP method to use
        # @param url [String, URI] the URL or URI to request
        # @param params [Hash] the query parameters to add to the URI. (Note that the URI may already include query parameters.)
        # @param headers [Hash] the request headers.
        # @param log [Boolean] whether to log each request URL and response code
        # @param max_retries [Integer] the maximum number of times to retry after a 429 or 503 with Retry-After
        # @param max_retry_delay [Integer] the maximum retry delay (in seconds) to accept in a Retry-After header
        # @param timeout [Integer] the request timeout in seconds (RestClient will use this to set both open and read timeouts)
        # @raise URI::InvalidURIError if the specified URL is invalid
        # rubocop:disable Metrics/ParameterLists
        def initialize(method, url, params: {}, headers: {}, log: true, max_retries: MAX_RETRIES, max_retry_delay: MAX_RETRY_DELAY_SECONDS,
                       timeout: DEFAULT_TIMEOUT_SECONDS)
          raise ArgumentError, "#{method} not supported" unless SUPPORTED_METHODS.include?(method)
          raise ArgumentError, 'url cannot be nil' unless (uri = Validator.uri_or_nil(url))

          @method = method
          @url_str = url_str_with_params(uri, params)
          @headers = headers
          @log = log
          @max_retries = max_retries
          @max_retry_delay = max_retry_delay
          @timeout = timeout
        end

        # rubocop:enable Metrics/ParameterLists

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
          return unless log && response&.code

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

        def execute_request(retries_remaining = max_retries)
          try_execute_request
        rescue RestClient::Exceptions::Timeout
          raise
        rescue RestClient::Exception => e
          response = e.response
          raise unless (retry_delay = retry_delay_from(response))

          wait_for_retry(response, retry_delay, retries_remaining)
          execute_request(retries_remaining - 1)
        end

        def try_execute_request
          RestClient::Request.execute(method: method, url: url_str, headers: headers, timeout: timeout).tap do |response|
            # Not all failed RestClient requests throw exceptions
            raise(exception_for(response)) unless response.code == 200
          end
        end

        def wait_for_retry(response, retry_delay, retries_remaining)
          raise RetryLimitExceeded.new(response, max_retries: max_retries) unless retries_remaining > 0
          raise RetryDelayTooLarge.new(response, delay: retry_delay, max_delay: max_retry_delay) if retry_delay > max_retry_delay

          sleep(retry_delay)
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

        # Returns the retry interval for the specified exception, or `nil`
        # if the response does not allow a retry.
        #
        # @param resp [RestClient::Response] the response
        # @return [Integer, nil] the retry delay in seconds, or `nil` if the response
        #         does not allow a retry
        def retry_delay_from(resp)
          return unless RETRY_STATUSES.include?(resp.code)
          return unless (retry_header_value = resp.headers[RETRY_HEADER])
          return unless (retry_delay_seconds = parse_retry_header_value(retry_header_value))

          [1, retry_delay_seconds.ceil].max
        end

        # @return [Float, nil] the retry delay in seconds, or `nil` if the delay cannot be parsed
        def parse_retry_header_value(v)
          # start by assuming it's a delay in seconds
          Float(v) # should be an integer but let's not count on it
        rescue ArgumentError
          # assume it's an HTTP-date
          parse_retry_after_date(v)
        end

        # Parses the specified RFC2822 datetime string and returns the interval between that
        # datetime and the current time in seconds
        #
        # @param date_str [String] an RFC2822 datetime string
        # @return [Float, nil] the interval between the current time and the specified datetime,
        #   or nil if `date_str` cannot be parsed
        def parse_retry_after_date(date_str)
          retry_after = DateTime.rfc2822(date_str).to_time
          retry_after - Time.now
        rescue ArgumentError
          logger.warn("Can't parse #{RETRY_HEADER} value #{date_str}")
          nil
        end

      end
    end
  end
end
