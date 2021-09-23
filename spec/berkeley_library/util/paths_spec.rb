require 'spec_helper'
require 'berkeley_library/util/paths'

module BerkeleyLibrary::Util
  describe Paths do
    describe :clean do
      {
        # nil
        nil => nil,

        # Already clean
        '' => '.',
        'abc' => 'abc',
        'abc/def' => 'abc/def',
        'a/b/c' => 'a/b/c',
        '.' => '.',
        '..' => '..',
        '../..' => '../..',
        '../../abc' => '../../abc',
        '/abc' => '/abc',
        '/' => '/',

        # Remove trailing slash
        'abc/' => 'abc',
        'abc/def/' => 'abc/def',
        'a/b/c/' => 'a/b/c',
        './' => '.',
        '../' => '..',
        '../../' => '../..',
        '/abc/' => '/abc',

        # Remove doubled slash
        'abc//def//ghi' => 'abc/def/ghi',
        '//abc' => '/abc',
        '///abc' => '/abc',
        '//abc//' => '/abc',
        'abc//' => 'abc',

        # Remove . elements
        'abc/./def' => 'abc/def',
        '/./abc/def' => '/abc/def',
        'abc/.' => 'abc',

        # Remove .. elements
        'abc/def/ghi/../jkl' => 'abc/def/jkl',
        'abc/def/../ghi/../jkl' => 'abc/jkl',
        'abc/def/..' => 'abc',
        'abc/def/../..' => '.',
        '/abc/def/../..' => '/',
        'abc/def/../../..' => '..',
        '/abc/def/../../..' => '/',
        'abc/def/../../../ghi/jkl/../../../mno' => '../../mno',

        # Combinations
        'abc/./../def' => 'def',
        'abc//./../def' => 'def',
        'abc/../../././../def' => '../../def'
      }.each do |orig, expected|
        it "clean(#{orig.inspect}) -> #{expected.inspect}" do
          expect(Paths.clean(orig)).to eq(expected)
        end
      end
    end

    describe :join do
      {
        # zero parameters
        [] => '',

        # one parameter
        [''] => '',
        ['a'] => 'a',

        # two parameters
        ['a', 'b'] => 'a/b',
        ['a', ''] => 'a',
        ['', 'b'] => 'b',
        ['/', 'a'] => '/a',
        ['/', ''] => '/',
        ['a/', 'b'] => 'a/b',
        ['a/', ''] => 'a',
        ['', ''] => ''
      }.each do |orig, expected|
        it "join(#{orig.map(&:inspect).join(', ')}) -> #{expected.inspect}" do
          expect(Paths.join(*orig)).to eq(expected)
        end
      end
    end
  end
end
