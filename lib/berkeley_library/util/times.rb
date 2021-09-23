require 'time'

module BerkeleyLibrary
  module Util
    module Times
      class << self
        include Times
      end

      # @param time [Time, Date] the time
      # @return the UTC time corresponding to `time`
      def ensure_utc(time)
        return unless time
        return time if time.respond_to?(:utc?) && time.utc?
        return time.getutc if time.respond_to?(:getutc)
        return time.to_time.getutc if time.respond_to?(:to_time)

        raise ArgumentError, "Not a date or time: #{time.inspect}"
      end
    end
  end
end
