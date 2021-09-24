require 'spec_helper'

module BerkeleyLibrary::Util
  describe URIs do
    describe :append do
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

      # TODO: make this work
      xit "doesn't append to a bare URI when there's nothing to append" do
        original_url = 'https://example.org'
        new_uri = URIs.append(original_url)
        expected_uri = URI(original_url)
        expect(new_uri).to eq(expected_uri)
      end

      # TODO: make this work
      xit "doesn't append to a bare URI when there's only a query string" do
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

      it 'rejects a query string if the original URI already has one' do
        original_uri = URI('https://example.org/foo/bar?baz=qux')
        expect { URIs.append(original_uri, '/qux?corge') }.to raise_error(URI::InvalidComponentError)
      end

      it 'rejects a fragment if the original URI already has one' do
        original_uri = URI('https://example.org/foo/bar#baz')
        expect { URIs.append(original_uri, '/qux#corge') }.to raise_error(URI::InvalidComponentError)
      end

      it 'rejects appending multiple queries' do
        original_uri = URI('https://example.org/foo/bar')
        expect { URIs.append(original_uri, 'baz?qux=corge', 'grault?plugh=xyzzy') }.to raise_error(URI::InvalidComponentError)
      end

      it 'rejects appending multiple fragments' do
        original_uri = URI('https://example.org/foo/bar')
        expect { URIs.append(original_uri, 'baz#qux', 'grault#plugh') }.to raise_error(URI::InvalidComponentError)
      end

      it 'rejects queries after fragments' do
        original_uri = URI('https://example.org/foo/bar')
        expect { URIs.append(original_uri, 'baz#qux', '?grault=plugh') }.to raise_error(URI::InvalidComponentError)
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
    end

    describe :get do
      it 'makes a GET request' do
        url = 'https://example.org/'
        params = { p1: 1, p2: 2 }
        headers = { 'X-help' => 'I am trapped in a unit test' }

        url_with_query = "#{url}?#{URI.encode_www_form(params)}"
        expected_body = 'Help! I am trapped in a unit test'
        stub_request(:get, url_with_query).with(headers: headers).to_return(body: expected_body)

        result = URIs.get(url, params: params, headers: headers)
        expect(result).to eq(expected_body)
      end
    end
  end
end
