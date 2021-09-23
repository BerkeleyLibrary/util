require 'spec_helper'
require 'berkeley_library/util/times'

module BerkeleyLibrary
  module Util
    describe Times do
      describe :ensure_utc do
        it 'returns a UTC time unchanged' do
          time = Time.parse('2021-02-05 16:19:11.37707 -0800')
          utc_time = time.getutc
          expect(Times.ensure_utc(utc_time)).to be(utc_time)
        end

        it 'converts a non-UTC time' do
          time = Time.parse('2021-02-06 08:19:11.37707 +0800')
          expect(Times.ensure_utc(time)).to eq(time.getutc)
          expect(time.gmt_offset).to eq(28_800), 'Times.ensure_utc() should not modify its argument'
        end

        it 'accepts a Date' do
          date = Date.new(2021, 2, 6)
          utc_time = Time.new(2021, 2, 6).getutc
          expect(Times.ensure_utc(date)).to eq(utc_time)
        end

        it 'accepts a Datetime' do
          datetime = DateTime.parse('2021-02-05 16:19:11.37707 -0800')
          utc_time = Time.parse('2021-02-06 00:19:11.37707 UTC')
          expect(Times.ensure_utc(datetime)).to eq(utc_time)
        end

        it 'rejects non-date/time objects' do
          # noinspection RubyYardParamTypeMatch
          expect { Times.ensure_utc(Object.new) }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
