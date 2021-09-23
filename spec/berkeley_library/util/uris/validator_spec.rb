require 'spec_helper'

module BerkeleyLibrary
  module Util
    module URIs
      describe Validator do
        describe :uri_or_nil do
          it 'returns a URI unchanged' do
            uri = URI.parse('http://example.org/')
            expect(Validator.uri_or_nil(uri)).to be(uri)
          end

          it 'converts a string to a URI' do
            url = 'http://example.org/'
            expect(Validator.uri_or_nil(url)).to eq(URI.parse(url))
          end

          it 'returns nil for nil' do
            expect(Validator.uri_or_nil(nil)).to be_nil
          end

          it 'raises an error for invalid URL strings' do
            bad_url = 'not a uri'
            expect { Validator.uri_or_nil(bad_url) }.to raise_error(URI::InvalidURIError)
          end
        end

        describe :url_str_or_nil do
          it 'returns a URL string for a URI' do
            uri = URI.parse('http://example.org/')
            expect(Validator.url_str_or_nil(uri)).to eq(uri.to_s)
          end

          it 'returns a URL string' do
            url = 'http://example.org/'
            expect(Validator.url_str_or_nil(url)).to eq(url)
          end

          it 'returns nil for nil' do
            expect(Validator.url_str_or_nil(nil)).to be_nil
          end

          it 'raises an error for invalid URL strings' do
            bad_url = 'not a uri'
            expect { Validator.url_str_or_nil(bad_url) }.to raise_error(URI::InvalidURIError)
          end
        end
      end
    end
  end
end
