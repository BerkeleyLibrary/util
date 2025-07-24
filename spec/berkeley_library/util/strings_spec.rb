require 'spec_helper'

module BerkeleyLibrary
  module Util
    describe Strings do
      describe :ascii_numeric do
        it 'returns true for ASCII numeric strings' do
          str = '8675309'
          expect(Strings.ascii_numeric?(str)).to be(true)
        end

        it 'returns false for non-ASCII numeric strings' do
          strs = %w[
            ٨٦٧٥٣٠٩
            八六七五三〇九
          ]
          aggregate_failures 'non-ASCII numeric strings' do
            strs.each do |str|
              expect(Strings.ascii_numeric?(str)).to be(false), "Expected #{str.inspect} to be non-ASCII-numeric"
            end
          end
        end

        it 'returns false for mixed ASCII numeric and non-numeric strings' do
          strs = [
            '867-5309',
            '867 5309',
            ' 8675309 '
          ]
          aggregate_failures 'ASCII mixed numeric and non-numeric strings' do
            strs.each do |str|
              expect(Strings.ascii_numeric?(str)).to be(false), "Expected #{str.inspect} to be non-ASCII-numeric"
            end
          end
        end
      end

      describe :diff_index do
        it 'returns nil for identical strings' do
          s = 'elvis'
          expect(Strings.diff_index(s, s)).to be_nil
        end

        it 'returns nil for non-strings' do
          expect(Strings.diff_index(2, ['2'])).to be_nil
        end

        it 'returns the index for different strings' do
          s1 = 'elvis aaron presley'
          s2 = 'elvis nikita presley'
          expect(Strings.diff_index(s1, s2)).to eq(6)
        end

        it 'returns the length of the shorter string for prefixes' do
          s1 = 'elvis'
          s2 = 'elvis aaron presley'
          expect(Strings.diff_index(s1, s2)).to eq(5)
          expect(Strings.diff_index(s2, s1)).to eq(5)
        end
      end
    end
  end
end
