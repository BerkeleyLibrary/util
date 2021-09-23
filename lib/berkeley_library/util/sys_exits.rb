module BerkeleyLibrary
  module Util
    # cf. BSD sysexits.h https://cgit.freebsd.org/src/tree/include/sysexits.h?h=releng/2.0
    module SysExits
      # successful termination
      EX_OK = 0

      # command line usage error
      EX_USAGE = 64

      # internal software error
      EX_SOFTWARE = 70 # command line usage error
    end
  end
end
