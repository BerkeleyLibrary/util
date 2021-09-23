require 'spec_helper'

module BerkeleyLibrary
  module Util
    module URIs
      describe Requester do
        describe :get do
          it 'returns an HTTP response body for a URL string' do
            url = 'https://example.org/'
            expected_body = 'Help! I am trapped in a unit test'
            stub_request(:get, url).to_return(body: expected_body)

            result = Requester.get(url)
            expect(result).to eq(expected_body)
          end

          it 'returns an HTTP response body for a URI' do
            uri = URI.parse('https://example.org/')
            expected_body = 'Help! I am trapped in a unit test'
            stub_request(:get, uri).to_return(body: expected_body)

            result = Requester.get(uri)
            expect(result).to eq(expected_body)
          end

          it 'appends query parameters' do
            url = 'https://example.org/'
            params = { p1: 1, p2: 2 }
            url_with_query = "#{url}?#{URI.encode_www_form(params)}"
            expected_body = 'Help! I am trapped in a unit test'
            stub_request(:get, url_with_query).to_return(body: expected_body)

            result = Requester.get(url, params: params)
            expect(result).to eq(expected_body)
          end

          it 'sends request headers' do
            url = 'https://example.org/'
            headers = { 'X-help' => 'I am trapped in a unit test' }
            expected_body = 'Help! I am trapped in a unit test'
            stub_request(:get, url).with(headers: headers).to_return(body: expected_body)

            result = Requester.get(url, headers: headers)
            expect(result).to eq(expected_body)
          end

          it "raises #{RestClient::Exception} in the event of an invalid response" do
            aggregate_failures 'responses' do
              [207, 400, 401, 403, 404, 405, 418, 451, 500, 503].each do |code|
                url = "http://example.edu/#{code}"
                stub_request(:get, url).to_return(status: code)

                expect { Requester.get(url) }.to raise_error(RestClient::Exception)
              end
            end
          end

          it 'handles redirects' do
            url1 = 'https://example.org/'
            url2 = 'https://example.edu/'
            stub_request(:get, url1).to_return(status: 302, headers: { 'Location' => url2 })
            expected_body = 'Help! I am trapped in a unit test'
            stub_request(:get, url2).to_return(body: expected_body)

            result = Requester.get(url1)
            expect(result).to eq(expected_body)
          end
        end
      end
    end
  end
end
