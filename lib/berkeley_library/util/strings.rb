module BerkeleyLibrary
  module Util
    module Strings

      ASCII_0 = '0'.ord
      ASCII_9 = '9'.ord

      def ascii_numeric?(s)
        s.chars.all? do |c|
          ord = c.ord
          ord >= ASCII_0 && ord <= ASCII_9
        end
      end

      # Locates the point at which two strings differ
      #
      # @return [Integer, nil] the index of the first character in either string
      #   that differs from the other, or `nil` if the strings are identical,
      #   or are not strings
      def diff_index(s1, s2)
        return unless string_like?(s1, s2)

        shorter, longer = s1.size > s2.size ? [s2, s1] : [s1, s2]
        shorter.chars.each_with_index do |c, i|
          return i if c != longer[i]
        end
        shorter.length if shorter.length < longer.length # otherwise they're equal
      end

      class << self
        include Strings
      end

      private

      def string_like?(*strs)
        strs.all? { |s| s.respond_to?(:chars) && s.respond_to?(:size) }
      end

    end
  end
end
