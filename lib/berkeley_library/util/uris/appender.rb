require 'berkeley_library/util/paths'
require 'uri'
require 'typesafe_enum'

module BerkeleyLibrary
  module Util
    module URIs

      # Appends the specified paths to the path of the specified URI, removing any extraneous slashes,
      # and builds a new URI with that path and the same scheme, host, query, fragment, etc.
      # as the original.
      class Appender
        attr_reader :original_uri, :elements

        # Creates and invokes a new {Appender}.
        #
        # @param uri [URI, String] the original URI
        # @param elements [Array<String, Symbol>] the URI elements to join.
        # @raise URI::InvalidComponentError if appending the specified elements would create an invalid URI
        def initialize(uri, *elements)
          raise ArgumentError, 'uri cannot be nil' unless (@original_uri = URIs.uri_or_nil(uri))

          @elements = elements.map(&:to_s)
          @elements.each_with_index do |element, elem_index|
            handle_element(element, elem_index)
          end
        end

        # Returns the new URI.
        #
        # @return [URI] a new URI appending the joined path elements.
        # @raise URI::InvalidComponentError if appending the specified elements would create an invalid URI
        def to_uri
          original_uri.dup.tap do |new_uri|
            new_path = Paths.join(new_uri.path, *path_elements)
            new_uri.path = Paths.ensure_abs(new_path)
            new_uri.query = query unless query_elements.empty?
            new_uri.fragment = fragment unless fragment_elements.empty?
          end
        end

        private

        def handle_element(element, elem_index)
          h_index = element.index('#')
          q_index = element.index('?')
          # per RFC 3986 §3, fragment (or query) can contain '?', but query can't contain '#'
          return start_fragment_at(elem_index) if h_index && (q_index.nil? || h_index < q_index)
          return start_query_at(elem_index) if q_index && !(in_query? || in_fragment?)

          add_element(element)
        end

        def state
          @state ||= :path
        end

        def in_query?
          state == :query
        end

        def in_fragment?
          state == :fragment
        end

        def query
          query_elements.join
        end

        def fragment
          fragment_elements.join
        end

        def path_elements
          @path_elements ||= []
        end

        def query_elements
          @query_elements ||= [].tap { |e| e << original_uri.query if original_uri.query }
        end

        def fragment_elements
          @fragment_elements ||= [].tap { |e| e << original_uri.fragment if original_uri.fragment }
        end

        def start_query_at(elem_index)
          handle_query_start(elem_index)
          @state = :query
        end

        def start_fragment_at(elem_index)
          raise URI::InvalidComponentError, err_too_many_fragments(elem_index) unless fragment_elements.empty?
          raise URI::InvalidComponentError, err_too_many_fragments(elem_index) if too_many_fragments?(elem_index)

          handle_fragment_start(elem_index)
          @state = :fragment
        end

        def too_many_fragments?(elem_index)
          e = elements[elem_index]
          e.index('#', 1 + e.index('#'))
        end

        def add_element(e)
          return fragment_elements << e if in_fragment?
          return query_elements << e if in_query? || (e.include?('&') && !query_elements.empty?)

          path_elements << e
        end

        def handle_query_start(elem_index)
          element = elements[elem_index]

          # if there's anything before the '?', we treat that excess as a path element
          excess, q_start = split_around(element, element.index('?'))
          q_start = push_fragment_start(elem_index, q_start)

          query_elements << q_start
          path_elements << excess
        end

        # if the fragment starts in the middle of this element, we keep the part before
        # the fragment delimiter '#', and push the rest (w/'#') back onto the next element
        # to be parsed in the next iteration
        def push_fragment_start(elem_index, q_start)
          return q_start unless (f_index = q_start.index('#'))

          next_index = elem_index + 1
          q_start, q_next = split_around(q_start, f_index) # NOTE: this doesn't return the '#'
          elements[next_index] = "##{q_next}#{elements[next_index]}" #       so we prepend one here
          q_start
        end

        def handle_fragment_start(elem_index)
          element = elements[elem_index]

          # if there's anything before the '#', we treat that excess as a path element,
          # or as a query element if there's a query
          excess, f_start = split_around(element, element.index('#'))

          fragment_elements << f_start
          if in_query?
            query_elements << excess
          else
            path_elements << excess
          end
        end

        def split_around(s, i)
          [s[0...i], s[(i + 1)..]]
        end

        def err_too_many_fragments(elem_index)
          "#{elements[elem_index].inspect}: URI already has a fragment: #{fragment.inspect}"
        end
      end
    end
  end
end
