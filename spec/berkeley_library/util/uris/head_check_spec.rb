require 'spec_helper'
require 'okcomputer'
require 'berkeley_library/util/uris/head_check'
require 'base64'

module BerkeleyLibrary
  module Util
    RSpec.describe HeadCheck do
      let(:url) { 'http://example.com' }
      let(:check) { described_class.new(url) }
      let(:mock_response) { instance_double(RestClient::Response) }

      before do
        allow(BerkeleyLibrary::Util::URIs).to receive(:head_response).and_return(mock_response)
      end

      describe '#perform_request' do
        context 'without basic auth' do
          it 'does not add Authorization header' do
            check.perform_request
            expect(BerkeleyLibrary::Util::URIs).not_to have_received(:head_response).with(anything, hash_including('Authorization' => anything), anything)
          end

          it 'calls URIs.head_response with the correct URL' do
            check.perform_request
            expect(BerkeleyLibrary::Util::URIs).to have_received(:head_response).with(URI(url), headers: {}, log: false)
          end
        end

        context 'with basic auth' do
          let(:user) { 'user' }
          let(:password) { 'pass' }

          # Stub the configuration on the instance directly
          before do
            allow(check).to receive(:basic_auth_options).and_return([user, password])
          end

          it 'adds the Authorization header' do
            expected_headers = { 'Authorization' => "Basic #{Base64.strict_encode64("#{user}:#{password}")}" }

            check.perform_request
            expect(BerkeleyLibrary::Util::URIs).to have_received(:head_response).with(URI(url), headers: expected_headers, log: false)
          end
        end

        context 'when URIs.head_response raises an error' do
          let(:error_message) { 'Something went wrong' }

          before do
            allow(BerkeleyLibrary::Util::URIs).to receive(:head_response).and_raise(StandardError, error_message)
          end

          it 'raises an OkComputer::HttpCheck::ConnectionFailed error' do
            expect { check.perform_request }.to raise_error(OkComputer::HttpCheck::ConnectionFailed, error_message)
          end
        end
      end
    end
  end
end
