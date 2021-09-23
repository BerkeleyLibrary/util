require 'stringio'

module BerkeleyLibrary
  module Util
    module StringIOs
      class << self
        include StringIOs
      end

      # Returns the byte (**not** character) at the specified byte index
      # in the specified `StringIO`.
      #
      # @param s [StringIO] the StringIO to search in
      # @param i [Integer] the byte index
      # @return [Integer, nil] the byte, or nil if the byte index is invalid.
      def getbyte(s, i)
        return if i >= s.size
        return if s.size + i < 0

        pos_orig = s.pos
        begin
          s.seek(i >= 0 ? i : s.size + i)
          s.getbyte
        ensure
          s.seek(pos_orig)
        end
      end
    end
  end
end
