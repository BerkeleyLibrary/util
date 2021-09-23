require 'spec_helper'

module BerkeleyLibrary
  module Util
    describe Strings do
      describe :diff_index do
        it 'returns nil for identical strings' do
          s = 'elvis'
          expect(Strings.diff_index(s, s)).to be_nil
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
