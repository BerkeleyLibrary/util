module BerkeleyLibrary
  module Util
    module Arrays
      class << self
        # Clients can chose to call class methods directly, or include the module
        include Arrays
      end

      # Recursively checks whether the specified list contains, in the
      # same order, all values in the other specified list (additional codes
      # in between are fine)
      #
      # @param subset [Array] the values to look for
      # @param superset [Array] the list of values to look in
      # @return boolean True if all values were found, false otherwise
      def ordered_superset?(superset:, subset:)
        !find_indices(in_array: superset, for_array: subset).nil?
      end

      # Counts how many contiguous elements from the start of an
      # sequence of values satisfy the given block.
      #
      # @overload count_while(arr:)
      #   Returns an enumerator.
      #   @param values [Enumerable] the values
      #   @return [Enumerator] the enumerator.
      # @overload count_while(arr:, &block)
      #   Passes elements to the block until the block returns nil or false,
      #   then stops iterating and returns the count of matching elements.
      #   @param values [Enumerable] the values
      #   @return [Integer] the count
      def count_while(values:)
        return to_enum(:count_while, values: values) unless block_given?

        values.inject(0) do |count, x|
          matched = yield x
          break count unless matched

          count + 1
        end
      end

      # Given two lists, one of which is a superset of the other, with elements
      # in the same order (but possibly with additional elements in the superset),
      # returns an array the length of the subset, containing for each element in
      # the subset the index of the corresponding element in the superset.
      #
      # @overload find_matching_indices(for_array:, in_array:)
      #   For each value in `for_array`, finds the index of the first equal value
      #   in `in_array` after the previously matched value.
      #   @param in_array [Array] the list of values to look in
      #   @param for_array [Array] the values to look for
      #   @return [Array<Integer>, nil] the indices in `in_array` of each value in `for_array`,
      #     or `nil` if not all values could be found
      #
      # @overload find_matching_indices(for_array:, in_array:)
      #   For each value in `for_array`, finds the index of the first value
      #   in `in_array` after the previously matched value that matches
      #   the specified match function.
      #   @param in_array [Array] the list of values to look in
      #   @param for_array [Array] the values to look for
      #   @yieldparam source [Object] the value to compare
      #   @yieldparam target [Object] the value to compare against
      #   @return [Array<Integer>, nil] the indices in `in_array` of each value in `for_array`,
      #     or `nil` if not all values could be found
      def find_indices(for_array:, in_array:, &block)
        return find_indices_matching(for_array, in_array, &block) if block_given?

        find_all_indices(for_array, in_array)
      end

      # Given a block or a value, finds the index of the first matching value
      # at or after the specified start index.
      #
      # @overload find_index(value, in_array:, start_index:)
      #   Finds the first index of the specified value.
      #   @param value [Object] the value to find
      #   @param in_array [Array] the array to search
      #   @param start_index [Integer] the index to start with
      #   @return [Integer, nil] the index, or `nil` if no value matches
      # @overload find_index(&block)
      #   Finds the index of the first value matching
      #   the specified block.
      #   @param in_array [Array] the array to search
      #   @param start_index [Integer] the index to start with
      #   @yieldreturn [Boolean] whether the element matches
      #   @return [Integer, nil] the index, or `nil` if no value matches
      # @overload find_index
      #   @param in_array [Array] the array to search
      #   @param start_index [Integer] the index to start with
      #   @return [Enumerator] a new enumerator
      def find_index(*args, in_array:, start_index: 0, &block)
        raise ArgumentError, "wrong number of arguments (given #{value.length}, expected 0..1" if args.size > 1
        return Enumerator.new { |y| find_index(in_array: in_array, start_index: start_index, &y) } if args.empty? && !block_given?
        return unless (relative_index = in_array[start_index..].find_index(*args, &block))

        relative_index + start_index
      end

      # Given an array of unique integers _a<sub>1</sub>_, returns a new array
      # _a<sub>2</sub>_ in which the value at each index _i<sub>2</sub>_ is the
      # index _i<sub>1</sub>_ at which that value was found in _a<sub>1</sub>_.
      # E.g., given `[0, 2, 3]`, returns `[0, nil, 1, 2]`. The indices need
      # not be in order but must be unique.
      #
      # @param arr [Array<Integer>, nil] the array to invert.
      # @return [Array<Integer, nil>, nil] the inverted array, or nil if the input array is nil
      # @raise TypeError if `arr` is not an array of integers
      # @raise ArgumentError if `arr` contains duplicate values
      def invert(arr)
        return unless arr

        # noinspection RubyNilAnalysis
        Array.new(arr.size).tap do |inv|
          arr.each_with_index do |v, i|
            next inv[v] = i unless (prev_index = inv[v])

            raise ArgumentError, "Duplicate value #{v} at index #{i} already found at #{prev_index}"
          end
        end
      end

      # Merges two arrays in an order-preserving manner.
      # @param a1 [Array] the first array
      # @param a2 [Array] the second array
      # @return [Array] a merged array that is an ordered superset of both `a1` and `a2`
      # @see Arrays#ordered_superset?
      def merge(a1, a2)
        return a1 if a2.empty?
        return a2 if a1.empty?

        shorter, longer = a1.size > a2.size ? [a2, a1] : [a1, a2]
        do_merge(shorter, longer)
      end

      private

      def do_merge(shorter, longer)
        shorter.each_with_index do |v, ix_s|
          next unless (ix_l = longer.find_index(v))

          shorter_unmatched = shorter[0...ix_s]
          longer_unmatched = longer[0...ix_l]
          all_unmatched = sort_by_first_and_flatten(shorter_unmatched, longer_unmatched)
          return (all_unmatched << v) + merge(shorter[ix_s + 1..], longer[ix_l + 1..])
        end

        sort_by_first_and_flatten(longer, shorter)
      end

      def sort_by_first_and_flatten(a1, a2)
        return a1 if a2.empty?
        return a2 if a1.empty?
        return a2 + a1 if a1.first.respond_to?(:>) && a1.first > a2.first

        a1 + a2
      end

      def find_all_indices(source, target)
        source.each_with_object([]) do |src, target_indices|
          target_offset = (target_indices.last&.+ 1) || 0
          return nil unless (target_index = find_index(src, in_array: target, start_index: target_offset))

          target_indices << target_index
        end
      end

      def find_indices_matching(source, target)
        source.each_with_object([]) do |src, target_indices|
          target_offset = (target_indices.last&.+ 1) || 0
          return nil unless (target_index = find_index(in_array: target, start_index: target_offset) { |tgt| yield src, tgt })

          target_indices << target_index
        end
      end
    end
  end
end
