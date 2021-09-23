require 'berkeley_library/util/stringios'

module BerkeleyLibrary
  module Util
    # This module, modeled on the {https://golang.org/pkg/path/ Go `path` package},
    # provides utility routines for modifying paths separated by forward slashes,
    # such as URL paths. For system-dependent file paths, use
    # {https://ruby-doc.org/stdlib-2.7.0/libdoc/pathname/rdoc/Pathname.html `Pathname`}
    # instead.
    module Paths
      include BerkeleyLibrary::Util::StringIOs

      class << self
        include Paths
      end

      # Returns the shortest path name equivalent to `path` by purely lexical
      # processing by:
      #
      # 1. replacing runs of multiple `/` with a single `/`
      # 2. eliminating all `.` (current directory) elements
      # 3. eliminating all `<child>/..` in favor of directly
      #    referencing the parent directory
      # 4. replaing all `/..` at the beginning of the path
      #    with a single leading `/`
      #
      # The returned path ends in a slash only if it is the root `/`.
      # @see https://9p.io/sys/doc/lexnames.html Rob Pike, "Lexical File Names in Plan 9 or Getting Dot-Dot Right"
      #
      # @param path [String, nil] the path to clean
      # @return [String, nil] the cleaned path, or `nil` for a nil path.
      def clean(path)
        return unless path
        return '.' if ['', '.'].include?(path)

        StringIO.new.tap do |out|
          out << '/' if path[0] == '/'
          dotdot = (r = out.size)
          r, dotdot = process_next(r, dotdot, path, out) while r < path.size
          out << '.' if out.pos == 0
        end.string
      end

      # Joins any number of path elements into a single path, separating
      # them with slashes, ignoring empty elements and passing the result
      # to {Paths#clean}.
      #
      # @param elements [Array<String>] the elements to join
      # @return [String] the joined path
      def join(*elements)
        elements = elements.reject { |e| [nil, ''].include?(e) }
        joined_raw = elements.join('/')
        return '' if joined_raw == ''

        clean(joined_raw)
      end

      private

      def process_next(r, dotdot, path, out)
        # empty path element, or .
        return r + 1, dotdot if empty_or_dot?(r, path)
        # .. element: remove to last /
        return handle_dotdot(r, dotdot, path, out) if dotdot?(r, path)

        # real path element
        [append_from(r, path, out), dotdot]
      end

      def handle_dotdot(r, dotdot, path, out)
        if out.pos > dotdot
          backtrack_to_dotdot(out, dotdot)
        elsif path[0] != '/'
          dotdot = append_dotdot(out)
        end

        [r + 2, dotdot]
      end

      def dotdot?(r, path)
        path[r] == '.' && (r + 2 == path.size || path[r + 2] == '/')
      end

      def empty_or_dot?(r, path)
        path[r] == '/' || (path[r] == '.' && (r + 1 == path.size || path[r + 1] == '/'))
      end

      def append_from(r, path, out)
        out << '/' if (path[0] == '/' && out.pos != 1) || (path[0] != '/' && out.pos != 0)
        while r < path.size && path[r] != '/'
          out << path[r]
          r += 1
        end
        r
      end

      def append_dotdot(out)
        out << '/' if out.pos > 1
        out << '..'
        out.pos
      end

      def backtrack_to_dotdot(out, dotdot)
        out.seek(-1, IO::SEEK_CUR)
        out.seek(-1, IO::SEEK_CUR) while out.pos > dotdot && getbyte(out, out.pos) != 47 # '/' is ASCII 37
        out.truncate(out.pos)
      end

    end
  end
end
