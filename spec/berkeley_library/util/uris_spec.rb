require 'spec_helper'

module BerkeleyLibrary::Util
  describe URIs do
    describe :append do
      it 'rejects a nil URI' do
        expect { URIs.append(nil, 'foo') }.to raise_error(ArgumentError)
      end

      it 'appends paths' do
        original_uri = URI('https://example.org/foo/bar')
        new_uri = URIs.append(original_uri, 'qux', 'corge', 'garply')
        expect(new_uri).to eq(URI('https://example.org/foo/bar/qux/corge/garply'))
      end

      it 'appends paths to bare URIs without root' do
        original_url = 'https://example.org'
        new_uri = URIs.append(original_url, 'foo', 'bar')
        expected_uri = URI('https://example.org/foo/bar')
        expect(new_uri).to eq(expected_uri)
      end

      it 'returns a bare URI when there\'s nothing to append' do
        original_url = 'https://example.org'
        new_uri = URIs.append(original_url)
        expected_uri = URI(original_url)
        expect(new_uri).to eq(expected_uri)
      end

      it 'appends to a bare URI even when there\'s only a query string' do
        original_url = 'https://example.org'
        new_uri = URIs.append(original_url, '?foo=bar')
        expected_uri = URI("#{original_url}?foo=bar")
        expect(new_uri).to eq(expected_uri)
      end

      it 'does not modify the original URI' do
        original_uri = URI('https://example.org/foo/bar')
        original_url = original_uri.to_s
        new_uri = URIs.append(original_uri, 'qux', 'corge', 'garply')
        expect(new_uri).not_to be(original_uri)
        expect(original_uri.to_s).to eq(original_url)
      end

      it 'removes extraneous slashes' do
        original_uri = URI('https://example.org/foo/bar')
        new_uri = URIs.append(original_uri, '/qux', '/corge/', '//garply')
        expect(new_uri).to eq(URI('https://example.org/foo/bar/qux/corge/garply'))
      end

      it 'preserves queries' do
        original_uri = URI('https://example.org/foo/bar?baz=qux')
        new_uri = URIs.append(original_uri, '/qux', '/corge/', '//garply')
        expect(new_uri).to eq(URI('https://example.org/foo/bar/qux/corge/garply?baz=qux'))
      end

      it 'preserves fragments' do
        original_uri = URI('https://example.org/foo/bar#baz')
        new_uri = URIs.append(original_uri, '/qux', '/corge/', '//garply')
        expect(new_uri).to eq(URI('https://example.org/foo/bar/qux/corge/garply#baz'))
      end

      it 'accepts a query string if no previous query present' do
        original_uri = URI('https://example.org/foo/bar#baz')
        new_uri = URIs.append(original_uri, '/qux', '/corge/', '//garply?grault=xyzzy')
        expect(new_uri).to eq(URI('https://example.org/foo/bar/qux/corge/garply?grault=xyzzy#baz'))
      end

      it 'allows the ? to be passed separately' do
        original_uri = URI('https://example.org/foo/bar#baz')
        new_uri = URIs.append(original_uri, '/qux', '/corge/', '//garply', '?', 'grault=xyzzy')
        expect(new_uri).to eq(URI('https://example.org/foo/bar/qux/corge/garply?grault=xyzzy#baz'))
      end

      it 'appends query parameters with &' do
        original_uri = URI('https://example.org/foo/bar#baz')
        new_uri = URIs.append(original_uri, '/qux', '/corge/', '//garply?grault=xyzzy', '&plugh=flob')
        expect(new_uri).to eq(URI('https://example.org/foo/bar/qux/corge/garply?grault=xyzzy&plugh=flob#baz'))
      end

      it 'appends query parameters to original URI query' do
        original_uri = URI('https://example.org/foo/bar/qux/corge/garply?grault=xyzzy')
        new_uri = URIs.append(original_uri, '&plugh=flob')
        expect(new_uri).to eq(URI('https://example.org/foo/bar/qux/corge/garply?grault=xyzzy&plugh=flob'))
      end

      it 'treats & as a path element if no query is present' do
        original_uri = URI('https://example.org/foo/bar#baz')
        new_uri = URIs.append(original_uri, '/qux', '/corge/', 'garply', '&plugh=flob')
        expect(new_uri).to eq(URI('https://example.org/foo/bar/qux/corge/garply/&plugh=flob#baz'))
      end

      it 'accepts a fragment if no previous fragment present' do
        original_uri = URI('https://example.org/foo/bar?baz=qux')
        new_uri = URIs.append(original_uri, '/qux', '/corge/', '//garply#grault')
        expect(new_uri).to eq(URI('https://example.org/foo/bar/qux/corge/garply?baz=qux#grault'))
      end

      it 'rejects a fragment if the original URI already has one' do
        original_uri = URI('https://example.org/foo/bar#baz')
        expect { URIs.append(original_uri, '/qux#corge') }.to raise_error(URI::InvalidComponentError)
      end

      # Per RFC3986, "3.4. Query"
      it 'allows queries containing ?' do
        original_uri = URI('https://example.org/foo/bar')
        expected_url = "#{original_uri}/baz?qux=corge?grault?plugh=xyzzy"
        expected_uri = URI.parse(expected_url)

        uri1 = URIs.append(original_uri, 'baz?qux=corge', '?grault?plugh=xyzzy')
        expect(uri1).to eq(expected_uri)

        uri2 = URIs.append(original_uri, 'baz?qux=corge?grault?plugh=xyzzy')
        expect(uri2).to eq(expected_uri)
      end

      # Per RFC3986, "3.4. Query"
      it 'allows queries containing /' do
        original_uri = URI('https://example.org/foo/bar')
        expected_url = "#{original_uri}/baz?qux=corge/grault/plugh=xyzzy"
        expected_uri = URI.parse(expected_url)

        uri1 = URIs.append(original_uri, 'baz?qux=corge', '/grault/plugh=xyzzy')
        expect(uri1).to eq(expected_uri)

        uri2 = URIs.append(original_uri, 'baz?qux=corge/grault/plugh=xyzzy')
        expect(uri2).to eq(expected_uri)
      end

      it 'rejects fragments containing #' do
        original_uri = URI('https://example.org/foo/bar')
        expect { URIs.append(original_uri, 'baz#qux', 'grault#plugh') }.to raise_error(URI::InvalidComponentError)
        expect { URIs.append(original_uri, 'baz#qux#plugh') }.to raise_error(URI::InvalidComponentError)
      end

      # Per RFC3986, "3.5. Fragment"
      it 'allows fragments containing ?' do
        original_uri = URI('https://example.org/foo/bar')
        expected_url = "#{original_uri}/baz#qux?grault=plugh"
        expected_uri = URI.parse(expected_url)

        uri1 = URIs.append(original_uri, 'baz#qux', '?grault=plugh')
        expect(uri1).to eq(expected_uri)

        uri2 = URIs.append(original_uri, 'baz#qux?grault=plugh')
        expect(uri2).to eq(expected_uri)
      end

      # Per RFC3986, "3.5. Fragment"
      it 'allows fragments containing /' do
        original_uri = URI('https://example.org/foo/bar')
        expected_url = "#{original_uri}/baz#qux/grault=plugh"
        expected_uri = URI.parse(expected_url)

        uri1 = URIs.append(original_uri, 'baz#qux', '/grault=plugh')
        expect(uri1).to eq(expected_uri)

        uri2 = URIs.append(original_uri, 'baz#qux/grault=plugh')
        expect(uri2).to eq(expected_uri)
      end

      it 'correctly handles fragments in mid-path-segment' do
        original_uri = URI('https://example.org/foo/bar')
        new_uri = URIs.append(original_uri, 'qux#corge')
        expect(new_uri).to eq(URI('https://example.org/foo/bar/qux#corge'))
      end

      it 'correctly handles fragments in query start' do
        original_uri = URI('https://example.org/foo/bar')
        new_uri = URIs.append(original_uri, '?qux=corge&grault=plugh#xyzzy')
        expect(new_uri).to eq(URI('https://example.org/foo/bar?qux=corge&grault=plugh#xyzzy'))
      end

      it 'correctly handles fragments in mid-query' do
        original_uri = URI('https://example.org/foo/bar')
        new_uri = URIs.append(original_uri, '?qux=corge', '&grault=plugh#xyzzy')
        expect(new_uri).to eq(URI('https://example.org/foo/bar?qux=corge&grault=plugh#xyzzy'))
      end

      it 'rejects invalid characters' do
        original_uri = URI('https://example.org/')
        expect { URIs.append(original_uri, '精力善用') }.to raise_error(URI::InvalidComponentError)
      end

      it 'accepts percent-encoded path segments' do
        original_uri = URI('https://example.org/')
        encoded_segment = URIs.path_escape('精力善用')
        new_uri = URIs.append(original_uri, encoded_segment, 'foo.html')
        expected_url = "https://example.org/#{encoded_segment}/foo.html"
        expect(new_uri).to eq(URI(expected_url))
      end

      it 'accepts path segments with allowed punctuation' do
        original_uri = URI('https://example.org/')
        path = 'foo/bar/baz@qux&corge=garply+grault$waldo/fred'
        new_uri = URIs.append(original_uri, path, 'plugh')
        expected_url = "#{original_uri}#{path}/plugh"
        expect(new_uri).to eq(URI(expected_url))
      end

    end

    describe 'requests' do
      let(:url) { 'https://example.org/' }
      let(:params) { { p1: 1, p2: 2 } }
      let(:headers) { { 'X-help' => 'I am trapped in a unit test' } }
      let(:url_with_query) { "#{url}?#{URI.encode_www_form(params)}" }
      let(:expected_body) { 'Help! I am trapped in a unit test' }

      describe :get do
        it 'makes a GET request' do
          stub_request(:get, url_with_query).with(headers: headers).to_return(body: expected_body)

          result = URIs.get(url, params: params, headers: headers)
          expect(result).to eq(expected_body)
        end

        it 'raises an error in the event of a 404' do
          stub_request(:get, url_with_query).with(headers: headers).to_return(status: 404, body: expected_body)

          expect { URIs.get(url, params: params, headers: headers) }.to raise_error(RestClient::NotFound)
        end
      end

      describe :get_response do
        it 'makes a GET request' do
          stub_request(:get, url_with_query).with(headers: headers).to_return(body: expected_body)

          response = URIs.get_response(url, params: params, headers: headers)
          expect(response.body).to eq(expected_body)
          expect(response.code).to eq(200)
        end

        it 'returns the response even for errors' do
          stub_request(:get, url_with_query).with(headers: headers).to_return(status: 404, body: expected_body)

          response = URIs.get_response(url, params: params, headers: headers)
          expect(response.body).to eq(expected_body)
          expect(response.code).to eq(404)
        end
      end

      describe :head do
        it 'makes a HEAD request' do
          expected_status = 200
          stub_request(:head, url_with_query).with(headers: headers).to_return(status: expected_status)

          result = URIs.head(url, params: params, headers: headers)
          expect(result).to eq(expected_status)
        end

        it 'returns the status even for unsuccessful requests' do
          expected_status = 404
          stub_request(:head, url_with_query).with(headers: headers).to_return(status: expected_status)

          result = URIs.head(url, params: params, headers: headers)
          expect(result).to eq(expected_status)
        end
      end

      describe :head_response do
        it 'makes a HEAD request' do
          stub_request(:head, url_with_query).with(headers: headers).to_return(body: expected_body)

          response = URIs.head_response(url, params: params, headers: headers)
          expect(response.body).to eq(expected_body)
          expect(response.code).to eq(200)
        end

        it 'returns the response even for errors' do
          stub_request(:head, url_with_query).with(headers: headers).to_return(status: 404, body: expected_body)

          response = URIs.head_response(url, params: params, headers: headers)
          expect(response.body).to eq(expected_body)
          expect(response.code).to eq(404)
        end
      end
    end

    describe :safe_parse_uri do
      it 'returns a URI unchanged' do
        uri = URI.parse('http://example.org/')
        expect(URIs.safe_parse_uri(uri)).to be(uri)
      end

      it 'converts a string to a URI' do
        url = 'http://example.org/'
        expect(URIs.safe_parse_uri(url)).to eq(URI.parse(url))
      end

      it 'returns nil for nil' do
        expect(URIs.safe_parse_uri(nil)).to be_nil
      end

      context 'invalid URL strings' do
        it 'returns nil' do
          bad_url = 'not a uri'
          expect(URIs.safe_parse_uri(bad_url)).to be_nil
        end

        it 'logs a warning' do
          logger = instance_double(Ougai::Logger)
          allow(BerkeleyLibrary::Logging).to receive(:logger).and_return(logger)

          bad_url = 'not a uri'
          expect(logger).to receive(:warn).with(/#{bad_url}/, kind_of(URI::InvalidURIError))
          expect(URIs.safe_parse_uri(bad_url)).to be_nil
        end
      end
    end

    describe :path_escape do
      let(:in_out) do
        {
          '' => '',
          'corge' => 'corge',
          'foo+bar' => 'foo+bar',
          'qux/quux' => 'qux%2Fquux',
          'foo bar baz' => 'foo%20bar%20baz',
          'Corge-Grault.Fred_Waldo~Plugh' => 'Corge-Grault.Fred_Waldo~Plugh',
          '25%' => '25%25',
          "\t !\"#$%&'()*+,/:;<=>?@[\\]^`{|}☺" => '%09%20%21%22%23$%25&%27%28%29%2A+%2C%2F:%3B%3C=%3E%3F@%5B%5C%5D%5E%60%7B%7C%7D%E2%98%BA',
          '精力善用' => '%E7%B2%BE%E5%8A%9B%E5%96%84%E7%94%A8'
        }
      end

      it 'escapes a path segment' do
        aggregate_failures do
          in_out.each do |in_str, out_str|
            expect(URIs.path_escape(in_str)).to eq(out_str)
          end
        end
      end

      it 'rejects non-strings' do
        str = in_out.keys.last
        expect { URIs.path_escape(str.bytes) }.to raise_error(ArgumentError)
      end

      it 'converts non-UTF-8 strings to UTF-8' do
        utf_16_be = Encoding.find('UTF-16BE')
        aggregate_failures do
          in_out.each do |in_str, out_str|
            encoded = in_str.encode(utf_16_be)
            expect(URIs.path_escape(encoded)).to eq(out_str)
          end
        end
      end
    end
  end
end
