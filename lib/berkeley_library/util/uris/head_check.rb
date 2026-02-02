require 'berkeley_library/util/uris'

module BerkeleyLibrary
  module Util
    class HeadCheck < ::OkComputer::HttpCheck

      def perform_request
        # original HttpCheck::perform_request uses open-uri to perform a GET request.
        # Timeout.timeout(request_timeout) do
        #   options = { read_timeout: request_timeout }

        #   if basic_auth_options.any?
        #     options[:http_basic_authentication] = basic_auth_options
        #   end

        #   url.read(options)
        # end

        headers = {}
        if basic_auth_options.any?
          user, password = basic_auth_options
          headers['Authorization'] = "Basic #{Base64.strict_encode64("#{user}:#{password}")}"
        end

        URIs.head_response(url, headers: headers, log: false)
      rescue => e
        raise OkComputer::HttpCheck::ConnectionFailed, e.message
      end
    end
  end
end
