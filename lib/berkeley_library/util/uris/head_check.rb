require 'berkeley_library/util/uris'

module BerkeleyLibrary
  module Util
    # :nocov:
    if defined?(::OkComputer)
      class HeadCheck < ::OkComputer::HttpCheck

        def perform_request
          headers = {}
          if basic_auth_options.any?
            user, password = basic_auth_options
            headers['Authorization'] = "Basic #{Base64.strict_encode64("#{user}:#{password}")}"
          end

          options = { headers: headers, log: false }
          options[:timeout] = request_timeout.to_i if request_timeout

          URIs.head_response(url, **options)
        rescue StandardError => e
          raise OkComputer::HttpCheck::ConnectionFailed, e
        end
      end
    end
    # :nocov:
  end
end
