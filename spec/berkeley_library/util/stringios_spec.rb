require 'spec_helper'

require 'berkeley_library/util/stringios'

module BerkeleyLibrary
  module Util
    describe StringIOs do
      describe :getbyte do
        let(:s) { '祇園精舎の鐘の声、諸行無常の響きあり。' }
        let(:bytes) { s.bytes }
        let(:sio) { StringIO.new(s) }

        it 'gets the byte at the specified byte index' do
          bytes.each_with_index do |b, i|
            expect(StringIOs.getbyte(sio, i)).to eq(b)
          end
        end

        it 'resets the current offset' do
          StringIOs.getbyte(sio, bytes.size / 2)
          expect(sio.pos).to eq(0)
        end

        it 'returns nil for a too-large positive offset' do
          expect(StringIOs.getbyte(s, bytes.size)).to be_nil
        end

        it 'returns nil for a too-large negative offset' do
          expect(StringIOs.getbyte(s, -(1 + bytes.size))).to be_nil
        end
      end
    end
  end
end
