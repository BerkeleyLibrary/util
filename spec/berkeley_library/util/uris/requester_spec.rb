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

          describe 'retries' do
            let(:url) { 'https://example.org/' }
            let(:expected_body) { 'Help! I am trapped in a unit test' }

            context 'handling 429 Too Many Requests' do
              context 'with Retry-After' do
                context 'in seconds' do
                  it 'retries after the specified delay' do
                    retry_after_seconds = 1

                    stub_request(:get, url)
                      .to_return(status: 429, headers: { 'Retry-After' => retry_after_seconds.to_s })
                      .to_return(status: 200, body: expected_body)

                    requester = Requester.new(:get, url)
                    expect(requester).to receive(:sleep).with(1).once

                    result = requester.make_request
                    expect(result).to eq(expected_body)
                  end

                  it 'handles a non-integer retry delay' do
                    retry_after_seconds = 1.5
                    stub_request(:get, url)
                      .to_return(status: 429, headers: { 'Retry-After' => retry_after_seconds.to_s })
                      .to_return(status: 200, body: expected_body)

                    requester = Requester.new(:get, url)
                    expect(requester).to receive(:sleep).with(2).once

                    result = requester.make_request
                    expect(result).to eq(expected_body)
                  end

                  it 'raises RetryDelayTooLarge if the delay is too large' do
                    retry_after_seconds = 10 + BerkeleyLibrary::Util::URIs::Requester::MAX_RETRY_DELAY_SECONDS

                    stub_request(:get, url)
                      .to_return(status: 429, headers: { 'Retry-After' => retry_after_seconds.to_s })

                    requester = Requester.new(:get, url)
                    expect(requester).not_to receive(:sleep)

                    expect { requester.make_request }.to raise_error(RetryDelayTooLarge) do |ex|
                      expect(ex.cause).to be_a(RestClient::TooManyRequests)
                    end
                  end

                  it 'raises RetryLimitExceeded if there are too many retries' do
                    retry_after_seconds = 1

                    stub_request(:get, url)
                      .to_return(status: 429, headers: { 'Retry-After' => retry_after_seconds.to_s })
                      .to_return(status: 429, headers: { 'Retry-After' => retry_after_seconds.to_s })

                    requester = Requester.new(:get, url, max_retries: 1)
                    expect(requester).to receive(:sleep).with(1).once

                    expect { requester.make_request }.to raise_error(RetryLimitExceeded) do |ex|
                      expect(ex.cause).to be_a(RestClient::TooManyRequests)
                    end
                  end
                end

                context 'as RFC2822 datetime' do
                  it 'retries after the specified delay' do
                    retry_after_seconds = 1
                    retry_after_datetime = (Time.now + retry_after_seconds)

                    stub_request(:get, url)
                      .to_return(status: 429, headers: { 'Retry-After' => retry_after_datetime.rfc2822 })
                      .to_return(status: 200, body: expected_body)

                    requester = Requester.new(:get, url)
                    expect(requester).to receive(:sleep).with(1).once

                    result = requester.make_request
                    expect(result).to eq(expected_body)
                  end

                  it 'handles a non-integer retry delay' do
                    retry_after_seconds = 2.75
                    retry_after_datetime = (Time.now + retry_after_seconds)

                    stub_request(:get, url)
                      .to_return(status: 429, headers: { 'Retry-After' => retry_after_datetime.rfc2822 })
                      .to_return(status: 200, body: expected_body)

                    requester = Requester.new(:get, url)
                    expected_value = a_value_within(1).of(retry_after_seconds)
                    expect(requester).to receive(:sleep).with(expected_value).once

                    result = requester.make_request
                    expect(result).to eq(expected_body)
                  end

                  it 'raises RetryDelayTooLarge if the delay is too large' do
                    retry_after_seconds = 10 + BerkeleyLibrary::Util::URIs::Requester::MAX_RETRY_DELAY_SECONDS
                    retry_after_datetime = (Time.now + retry_after_seconds)

                    stub_request(:get, url)
                      .to_return(status: 429, headers: { 'Retry-After' => retry_after_datetime.rfc2822 })

                    requester = Requester.new(:get, url)
                    expect(requester).not_to receive(:sleep)

                    expect { requester.make_request }.to raise_error(RetryDelayTooLarge) do |ex|
                      expect(ex.cause).to be_a(RestClient::TooManyRequests)
                    end
                  end

                  it 'raises RetryLimitExceeded if there are too many retries' do
                    retry_after_seconds = 1
                    retry_after_datetime = (Time.now + retry_after_seconds)

                    stub_request(:get, url)
                      .to_return(status: 429, headers: { 'Retry-After' => retry_after_datetime.rfc2822 })
                      .to_return(status: 429, headers: { 'Retry-After' => retry_after_datetime.rfc2822 })

                    requester = Requester.new(:get, url, max_retries: 1)
                    expect(requester).to receive(:sleep).with(1).once

                    expect { requester.make_request }.to raise_error(RetryLimitExceeded) do |ex|
                      expect(ex.cause).to be_a(RestClient::TooManyRequests)
                    end
                  end

                end

                it 'ignores an invalid Retry-After' do
                  stub_request(:get, url)
                    .to_return(status: 429, headers: { 'Retry-After' => 'the end of the world' })

                  requester = Requester.new(:get, url)
                  expect { requester.make_request }.to raise_error(RestClient::TooManyRequests)
                end
              end
            end

            context 'handling 503 Service Unavailable' do
              context 'with Retry-After' do
                context 'in seconds' do
                  it 'retries after the specified delay' do
                    retry_after_seconds = 1

                    stub_request(:get, url)
                      .to_return(status: 503, headers: { 'Retry-After' => retry_after_seconds.to_s })
                      .to_return(status: 200, body: expected_body)

                    requester = Requester.new(:get, url)
                    expect(requester).to receive(:sleep).with(1).once

                    result = requester.make_request
                    expect(result).to eq(expected_body)
                  end

                  it 'handles a non-integer retry delay' do
                    retry_after_seconds = 0.75
                    stub_request(:get, url)
                      .to_return(status: 503, headers: { 'Retry-After' => retry_after_seconds.to_s })
                      .to_return(status: 200, body: expected_body)

                    requester = Requester.new(:get, url)
                    expect(requester).to receive(:sleep).with(1).once

                    result = requester.make_request
                    expect(result).to eq(expected_body)
                  end

                  it 'raises RetryDelayTooLarge if the delay is too large' do
                    retry_after_seconds = 10 + BerkeleyLibrary::Util::URIs::Requester::MAX_RETRY_DELAY_SECONDS

                    stub_request(:get, url)
                      .to_return(status: 503, headers: { 'Retry-After' => retry_after_seconds.to_s })

                    requester = Requester.new(:get, url)
                    expect(requester).not_to receive(:sleep)

                    expect { requester.make_request }.to raise_error(RetryDelayTooLarge) do |ex|
                      expect(ex.cause).to be_a(RestClient::ServiceUnavailable)
                    end
                  end
                end

                context 'as RFC2822 datetime' do
                  it 'retries after the specified delay' do
                    retry_after_seconds = 1
                    retry_after_datetime = (Time.now + retry_after_seconds)

                    stub_request(:get, url)
                      .to_return(status: 503, headers: { 'Retry-After' => retry_after_datetime.rfc2822 })
                      .to_return(status: 200, body: expected_body)

                    requester = Requester.new(:get, url)
                    expect(requester).to receive(:sleep).with(1).once

                    result = requester.make_request
                    expect(result).to eq(expected_body)
                  end

                  it 'handles a non-integer retry delay' do
                    retry_after_seconds = 1.75
                    retry_after_datetime = (Time.now + retry_after_seconds)

                    stub_request(:get, url)
                      .to_return(status: 503, headers: { 'Retry-After' => retry_after_datetime.rfc2822 })
                      .to_return(status: 200, body: expected_body)

                    requester = Requester.new(:get, url)
                    expected_value = a_value_within(1).of(retry_after_seconds)
                    expect(requester).to receive(:sleep).with(expected_value).once

                    result = requester.make_request
                    expect(result).to eq(expected_body)
                  end

                  it 'raises RetryDelayTooLarge if the delay is too large' do
                    retry_after_seconds = 10 + BerkeleyLibrary::Util::URIs::Requester::MAX_RETRY_DELAY_SECONDS
                    retry_after_datetime = (Time.now + retry_after_seconds)

                    stub_request(:get, url)
                      .to_return(status: 503, headers: { 'Retry-After' => retry_after_datetime.rfc2822 })

                    requester = Requester.new(:get, url)
                    expect(requester).not_to receive(:sleep)

                    expect { requester.make_request }.to raise_error(RetryDelayTooLarge) do |ex|
                      expect(ex.cause).to be_a(RestClient::ServiceUnavailable)
                    end
                  end
                end

                it 'ignores an invalid Retry-After' do
                  stub_request(:get, url)
                    .to_return(status: 503, headers: { 'Retry-After' => 'the end of the world' })

                  requester = Requester.new(:get, url)
                  expect { requester.make_request }.to raise_error(RestClient::ServiceUnavailable)
                end

                it "raises #{RestClient::Exceptions::Timeout} when the request times out" do
                  url = 'http://example.edu/timeout'
                  stub_request(:get, url).to_raise(RestClient::Exceptions::Timeout)

                  expect { Requester.get(url, timeout: 10) }.to raise_error(RestClient::Exceptions::Timeout)
                end
              end
            end
          end

        end

        describe :head do
          it 'returns an HTTP status code for a URL string' do
            url = 'https://example.org/'
            expected_status = 203
            stub_request(:head, url).to_return(status: expected_status)

            result = Requester.head(url)
            expect(result).to eq(expected_status)
          end

          it 'returns an HTTP response body for a URI' do
            uri = URI.parse('https://example.org/')
            expected_status = 203
            stub_request(:head, uri).to_return(status: expected_status)

            result = Requester.head(uri)
            expect(result).to eq(expected_status)
          end

          it 'appends query parameters' do
            url = 'https://example.org/'
            params = { p1: 1, p2: 2 }
            url_with_query = "#{url}?#{URI.encode_www_form(params)}"
            expected_status = 203
            stub_request(:head, url_with_query).to_return(status: expected_status)

            result = Requester.head(url, params: params)
            expect(result).to eq(expected_status)
          end

          it 'appends query parameters to URL with existing params' do
            url = 'https://example.org/endpoint?foo=bar'
            params = { p1: 1, p2: 2 }
            url_with_query = "#{url}&#{URI.encode_www_form(params)}"
            expected_status = 203
            stub_request(:head, url_with_query).to_return(status: expected_status)

            result = Requester.head(url, params: params)
            expect(result).to eq(expected_status)
          end

          it 'sends request headers' do
            url = 'https://example.org/'
            headers = { 'X-help' => 'I am trapped in a unit test' }
            expected_status = 203
            stub_request(:head, url).with(headers: headers).to_return(status: expected_status)

            result = Requester.head(url, headers: headers)
            expect(result).to eq(expected_status)
          end

          it 'returns the status even for unsuccessful requests' do
            aggregate_failures 'responses' do
              [207, 400, 401, 403, 404, 405, 418, 451, 500, 503].each do |expected_status|
                url = "http://example.edu/#{expected_status}"
                stub_request(:head, url).to_return(status: expected_status)

                result = Requester.head(url)
                expect(result).to eq(expected_status)
              end
            end
          end

          it "raises #{RestClient::Exceptions::Timeout} when the request times out" do
            url = 'http://example.edu/timeout'
            stub_request(:head, url).to_raise(RestClient::Exceptions::Timeout)

            expect { Requester.head(url, timeout: 10) }.to raise_error(RestClient::Exceptions::Timeout)
          end

          it 'handles redirects' do
            url1 = 'https://example.org/'
            url2 = 'https://example.edu/'
            stub_request(:head, url1).to_return(status: 302, headers: { 'Location' => url2 })
            expected_status = 203
            stub_request(:head, url2).to_return(status: expected_status)

            result = Requester.head(url1)
            expect(result).to eq(expected_status)
          end

          it 'rejects a nil URI' do
            expect { Requester.head(nil) }.to raise_error(ArgumentError)
          end
        end

        describe 'logging' do
          attr_reader :logger

          before do
            @logger = instance_double(BerkeleyLibrary::Logging::Logger)
            allow(BerkeleyLibrary::Logging).to receive(:logger).and_return(logger)
          end

          context 'GET' do
            it 'logs request URLs and response codes for successful GET requests' do
              url = 'https://example.org/'
              expected_body = 'Help! I am trapped in a unit test'
              stub_request(:get, url).to_return(body: expected_body)

              expect(logger).to receive(:info).with(/#{url}.*200/)
              Requester.send(:get, url)
            end

            it 'can suppress logging for successful GET requests' do
              url = 'https://example.org/'
              expected_body = 'Help! I am trapped in a unit test'
              stub_request(:get, url).to_return(body: expected_body)

              expect(logger).not_to receive(:info)
              Requester.send(:get, url, log: false)
            end

            it 'logs request URLs and response codes for failed GET requests' do
              url = 'https://example.org/'
              status = 500
              stub_request(:get, url).to_return(status: status)

              expect(logger).to receive(:info).with(/#{url}.*#{status}/)
              expect { Requester.send(:get, url) }.to raise_error(RestClient::InternalServerError)
            end

            it 'can suppress logging for failed GET requests' do
              url = 'https://example.org/'
              stub_request(:get, url).to_return(status: 500)

              expect(logger).not_to receive(:info)
              expect { Requester.send(:get, url, log: false) }.to raise_error(RestClient::InternalServerError)
            end
          end

          context 'HEAD' do
            it 'logs request URLs and response codes for successful HEAD requests' do
              url = 'https://example.org/'
              expected_body = 'Help! I am trapped in a unit test'
              stub_request(:head, url).to_return(body: expected_body)

              expect(logger).to receive(:info).with(/#{url}.*200/)
              Requester.send(:head, url)
            end

            it 'can suppress logging for successful HEAD requests' do
              url = 'https://example.org/'
              expected_body = 'Help! I am trapped in a unit test'
              stub_request(:head, url).to_return(body: expected_body)

              expect(logger).not_to receive(:info)
              Requester.send(:head, url, log: false)
            end

            it 'logs request URLs and response codes for failed HEAD requests' do
              url = 'https://example.org/'
              status = 500
              stub_request(:head, url).to_return(status: status)

              expect(logger).to receive(:info).with(/#{url}.*#{status}/)
              expect(Requester.send(:head, url)).to eq(status)
            end

            it 'can suppress logging for failed HEAD requests' do
              url = 'https://example.org/'
              status = 500
              stub_request(:head, url).to_return(status: status)

              expect(logger).not_to receive(:info)
              expect(Requester.send(:head, url, log: false)).to eq(status)
            end
          end
        end

        describe :new do
          it 'rejects invalid URIs' do
            url = 'not a uri'
            Requester::SUPPORTED_METHODS.each do |method|
              expect { Requester.new(method, url) }.to raise_error(URI::InvalidURIError)
            end
          end

          it 'rejects nil URIs' do
            Requester::SUPPORTED_METHODS.each do |method|
              expect { Requester.new(method, nil) }.to raise_error(ArgumentError)
            end
          end

          it 'rejects unsupported methods' do
            url = 'https://example.org/'
            %i[put patch post].each do |method|
              expect { Requester.new(method, url) }.to raise_error(ArgumentError)
            end
          end
        end
      end
    end
  end
end
