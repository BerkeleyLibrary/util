require 'spec_helper'

require 'berkeley_library/util/arrays'

module BerkeleyLibrary::Util
  describe Arrays do
    describe :ordered_superset do
      let(:sup) { %w[a b c d e] }

      it 'returns true for an identical subset' do
        expect(Arrays.ordered_superset?(superset: sup, subset: sup.dup)).to eq(true)
      end

      it 'returns true for an empty subset' do
        expect(Arrays.ordered_superset?(superset: sup, subset: [])).to eq(true)
      end

      it 'returns true for an exact sublist' do
        subs = [
          %w[a b c],
          %w[b c d],
          %w[c d e]
        ]
        subs.each do |sub|
          expect(Arrays.ordered_superset?(superset: sup, subset: sub)).to eq(true)
        end
      end

      it 'returns true when the superset interpolates extra elements' do
        subs = [
          %w[a c e],
          %w[b d],
          %w[a b d e]
        ]
        subs.each do |sub|
          expect(Arrays.ordered_superset?(superset: sup, subset: sub)).to eq(true)
        end
      end

      it 'returns false for a too-large subset' do
        sub = %w[a b c d e f g]
        expect(Arrays.ordered_superset?(superset: sup, subset: sub)).to eq(false)
      end

      it 'returns false when extra elements are present' do
        subs = [
          %w[a b c x],
          %w[x b c d],
          %w[c d x e]
        ]
        subs.each do |sub|
          expect(Arrays.ordered_superset?(superset: sup, subset: sub)).to eq(false)
        end
      end
    end

    describe :count_while do
      it 'returns the count of matching elements' do
        a = [1, 3, 5, 2, 4, 6, 7, 11, 13]
        expect(Arrays.count_while(values: a, &:odd?)).to eq(3)
      end

      it 'returns 0 if the first element does not match' do
        a = [2, 4, 6, 7, 11, 13]
        expect(Arrays.count_while(values: a, &:odd?)).to eq(0)
      end

      it 'returns an enumerator if not passed a block' do
        a = [1, 3, 5, 2, 4, 6, 7, 11, 13]
        e = Arrays.count_while(values: a)
        expect(e.each(&:odd?)).to eq(3)
      end

      it 'works on non-arrays' do
        a = [1, 3, 5, 2, 4, 6, 7, 11, 13]
        e = Enumerator.new { |y| a.each { |x| y << x } }
        expect(Arrays.count_while(values: e, &:odd?)).to eq(3)
      end
    end

    describe :find_indices do
      let(:target) { %w[a b c d e] }

      it 'returns identity indices for an identical subset' do
        expect(Arrays.find_indices(for_array: target.dup, in_array: target)).to eq([0, 1, 2, 3, 4])
      end

      it 'returns an empty array for an empty subset' do
        expect(Arrays.find_indices(for_array: [], in_array: target)).to eq([])
      end

      it 'returns the expected subindices for an exact sublist' do
        sources = {
          %w[a b c] => [0, 1, 2],
          %w[b c d] => [1, 2, 3],
          %w[c d e] => [2, 3, 4]
        }
        sources.each do |source, expected|
          expect(Arrays.find_indices(for_array: source, in_array: target)).to eq(expected)
        end
      end

      it 'returns nil for a too-large subset' do
        source = %w[a b c d e f g]
        expect(Arrays.find_indices(for_array: source, in_array: target)).to be_nil
      end

      it 'returns nil when extra elements are present' do
        sources = [
          %w[a b c x],
          %w[x b c d],
          %w[c d x e]
        ]
        sources.each do |source|
          expect(Arrays.find_indices(for_array: source, in_array: target)).to be_nil
        end
      end

      it 'takes a comparison block' do
        sub = %i[a c e]
        expect(Arrays.find_indices(for_array: sub, in_array: target) { |source, target| target == source.to_s }).to eq([0, 2, 4])
      end
    end

    describe :find_index do
      let(:arr) { [0, 2, 4, 6, 4] }

      it 'finds an index based on a value' do
        expect(Arrays.find_index(4, in_array: arr)).to eq(2)
        expect(Arrays.find_index(4, in_array: arr, start_index: 3)).to eq(4)
      end

      it 'finds an index based on a block' do
        expect(Arrays.find_index(in_array: arr) { |x| x > 3 }).to eq(2)
        expect(Arrays.find_index(in_array: arr, start_index: 3) { |x| x < 5 }).to eq(4)
      end

      it 'returns nil if no equal value found' do
        expect(Arrays.find_index(7, in_array: arr)).to be_nil
        expect(Arrays.find_index(2, in_array: arr, start_index: 2)).to be_nil
      end

      it 'returns nil if no matching value found' do
        expect(Arrays.find_index(in_array: arr, &:odd?)).to be_nil
        expect(Arrays.find_index(in_array: arr, start_index: 2) { |x| x < 4 }).to be_nil
      end

      # rubocop:disable Lint/Void
      it 'returns an enumerator if given no arguments' do
        e = Arrays.find_index(in_array: arr)
        expect(e.each { |x| x > 3 }).to eq(2)

        e = Arrays.find_index(in_array: arr, start_index: 3)
        expect(e.each { |x| x < 5 }).to eq(4)
      end
      # rubocop:enable Lint/Void
    end

    describe :merge do
      it 'merges two arrays' do
        a1 = [1, 2, 3]
        a2 = [2, 3, 4]
        expect(Arrays.merge(a1, a2)).to eq([1, 2, 3, 4])
        expect(Arrays.merge(a2, a1)).to eq([1, 2, 3, 4])
      end

      it 'merges disjoint arrays' do
        a1 = [1, 3, 5]
        a2 = [2, 4, 6]
        expect(Arrays.merge(a1, a2)).to eq([1, 3, 5, 2, 4, 6])
      end

      it 'preserves duplicates' do
        a1 = [1, 2, 2, 3, 4, 5]
        a2 = [2, 4, 4, 5, 5, 6]

        merged = Arrays.merge(a1, a2)
        [a1, a2].each do |a|
          expect(Arrays.ordered_superset?(superset: merged, subset: a)).to eq(true), "merge(#{[a1.join, a2.join].inspect}): #{a.join} not found in #{merged.join}"
        end

        expected = [1, 2, 2, 3, 4, 4, 5, 5, 6]
        expect(merged.size).to eq(expected.size)
        expect(merged).to eq(expected)
      end

      it 'merges gappy arrays' do
        a1 = [1, 4, 5, 7, 9]
        a2 = [2, 3, 4, 7, 8, 9]

        merged = Arrays.merge(a1, a2)
        [a1, a2].each do |a|
          expect(Arrays.ordered_superset?(superset: merged, subset: a)).to eq(true), "merge(#{[a1.join, a2.join].inspect}): #{a.join} not found in #{merged.join}"
        end

        expected = [1, 2, 3, 4, 5, 7, 8, 9]
        expect(merged.size).to eq(expected.size)
        expect(merged).to eq(expected)
      end

      it 'preserves order when merging arrays with duplicates' do
        a1 = [1, 3, 2, 2, 4]
        a2 = [1, 2, 3, 2, 4]

        merged = Arrays.merge(a1, a2)
        [a1, a2].each do |a|
          expect(Arrays.ordered_superset?(superset: merged, subset: a)).to eq(true), "merge(#{[a1.join, a2.join].inspect}): #{a.join} not found in #{merged.join}"
        end

        expected = [1, 2, 3, 2, 2, 4]
        expect(merged.size).to eq(expected.size)
        expect(merged).to eq(expected)
      end

      it 'preserves nil' do
        a1 = [1, 3, nil, nil, 4]
        a2 = [1, nil, 3, nil, 4]

        merged = Arrays.merge(a1, a2)
        [a1, a2].each do |a|
          expect(Arrays.ordered_superset?(superset: merged, subset: a)).to eq(true), "merge(#{[a1.join, a2.join].inspect}): #{a.join} not found in #{merged.join}"
        end

        expected = [1, nil, 3, nil, nil, 4]
        expect(merged.size).to eq(expected.size)
        expect(merged).to eq(expected)
      end

      it 'works with non-comparable types' do
        a1 = [1, 3, 'two', 'two', 4]
        a2 = [1, 'two', 3, 'two', 4]

        merged = Arrays.merge(a1, a2)
        [a1, a2].each do |a|
          expect(Arrays.ordered_superset?(superset: merged, subset: a)).to eq(true), "merge(#{[a1.join, a2.join].inspect}): #{a.join} not found in #{merged.join}"
        end

        expected = [1, 'two', 3, 'two', 'two', 4]
        expect(merged.size).to eq(expected.size)
        expect(merged).to eq(expected)
      end

      it 'returns the larger array if the smaller is already a subarray' do
        a1 = [2, 3, 4]
        a2 = [1, 2, 3, 4, 5]

        merged = Arrays.merge(a1, a2)
        [a1, a2].each do |a|
          expect(Arrays.ordered_superset?(superset: merged, subset: a)).to eq(true), "merge(#{[a1.join, a2.join].inspect}): #{a.join} not found in #{merged.join}"
        end

        expected = a2
        expect(merged.size).to eq(expected.size)
        expect(merged).to eq(expected)

        expect(Arrays.merge(a2, a1)).to eq(expected)
      end

      it 'sorts where sorting preserves order' do
        a1 = [1, 2, 3, 4, 5]
        a2 = [2, 3, 6, 9]

        merged = Arrays.merge(a1, a2)
        [a1, a2].each do |a|
          expect(Arrays.ordered_superset?(superset: merged, subset: a)).to eq(true), "merge(#{[a1.join, a2.join].inspect}): #{a.join} not found in #{merged.join}"
        end

        expected = [1, 2, 3, 4, 5, 6, 9]
        expect(merged.size).to eq(expected.size)
        expect(merged).to eq(expected)

        expect(Arrays.merge(a2, a1)).to eq(expected)
      end

      it "doesn't muck up partial matches" do
        a1 = [1, 2, 3, 4, 5]
        a2 = [6, 9, 2, 3]

        merged = Arrays.merge(a1, a2)
        [a1, a2].each do |a|
          expect(Arrays.ordered_superset?(superset: merged, subset: a)).to eq(true), "merge(#{[a1.join, a2.join].inspect}): #{a.join} not found in #{merged.join}"
        end

        expected = [1, 6, 9, 2, 3, 4, 5]
        expect(merged.size).to eq(expected.size)
        expect(merged).to eq(expected)

        expect(Arrays.merge(a2, a1)).to eq(expected)
      end

      it "doesn't much up disjoints" do
        a1 = [1, 2, 3, 4, 5]
        a2 = [6, 9]

        merged = Arrays.merge(a1, a2)
        [a1, a2].each do |a|
          expect(Arrays.ordered_superset?(superset: merged, subset: a)).to eq(true), "merge(#{[a1.join, a2.join].inspect}): #{a.join} not found in #{merged.join}"
        end

        expected = [1, 2, 3, 4, 5, 6, 9]
        expect(merged.size).to eq(expected.size)
        expect(merged).to eq(expected)

        expect(Arrays.merge(a2, a1)).to eq(expected)
      end

      it 'works on a selection of random values' do
        next_int = ->(n) { (n * rand).to_i }
        rand_array = -> { (0...next_int.call(10)).map { next_int.call(10) } }
        aggregate_failures 'random values' do
          100.times do
            a1 = rand_array.call
            a2 = rand_array.call

            merged = Arrays.merge(a1, a2)
            [a1, a2].each do |a|
              expect(Arrays.ordered_superset?(superset: merged, subset: a)).to eq(true), "merge(#{[a1.join, a2.join].inspect}): #{a.join} not found in #{merged.join}"
            end
          end
        end
      end

    end

    describe :invert do
      it 'inverts an array of ints' do
        expect(Arrays.invert([0, 2, 3])).to eq([0, nil, 1, 2])
      end

      it 'fails if values are not ints' do
        # noinspection RubyYardParamTypeMatch
        expect { Arrays.invert(%i[a b c]) }.to raise_error(TypeError)
      end

      it 'fails if given duplicate values' do
        expect { Arrays.invert([1, 2, 3, 2]) }.to raise_error(ArgumentError)
      end
    end
  end
end
