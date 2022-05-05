require 'spec_helper'

module BerkeleyLibrary
  module Util
    describe Files do
      let(:basename) { File.basename(__FILE__, '.rb') }

      attr_reader :tmpdir

      before { @tmpdir = Dir.mktmpdir(basename) }
      after { FileUtils.remove_entry(tmpdir) }

      describe :file_exists? do
        it 'returns true for files that exist' do
          path = Pathname.new(tmpdir).join('exists').tap { |p| FileUtils.touch(p) }
          expect(path.exist?).to eq(true) # just to be sure
          path_str = path.to_s

          expect(Files.file_exists?(path)).to eq(true)
          expect(Files.file_exists?(path_str)).to eq(true)
        end

        it 'returns false for files that do not exist' do
          path = Pathname.new(tmpdir).join('not-exists')
          expect(path.exist?).to eq(false) # just to be sure
          path_str = path.to_s

          expect(Files.file_exists?(path)).to eq(false)
          expect(Files.file_exists?(path_str)).to eq(false)
        end
      end

      describe :parent_exists? do
        it 'returns true for paths whose parent exists' do
          parent = Pathname.new(tmpdir).join('parent').tap(&:mkdir)
          expect(parent.exist?).to eq(true) # just to be sure
          path = parent.join('child')
          path_str = path.to_s

          expect(Files.parent_exists?(path)).to eq(true)
          expect(Files.parent_exists?(path_str)).to eq(true)
        end

        it 'returns false for paths whose parent does not' do
          parent = Pathname.new(tmpdir).join('parent')
          expect(parent.exist?).to eq(false) # just to be sure
          path = parent.join('child')
          path_str = path.to_s

          expect(Files.parent_exists?(path)).to eq(false)
          expect(Files.parent_exists?(path_str)).to eq(false)
        end
      end

      describe :reader_like? do
        it 'returns true for a readable file' do
          filename = File.join(tmpdir, 'out')
          FileUtils.touch(filename)

          File.open(filename, 'rb') do |out|
            expect(Files.reader_like?(out)).to eq(true)
          end
        end

        it 'returns true for a StringIO' do
          out = StringIO.new
          expect(Files.reader_like?(out)).to eq(true)
        end

        it 'returns true for a Tempfile' do
          out = Tempfile.new('out')
          begin
            expect(Files.reader_like?(out)).to eq(true)
          ensure
            out.close
            out.unlink
          end
        end

        it 'returns false for something that is not reader-like' do
          expect(Files.reader_like?('not an IO')).to eq(false)
        end
      end

      describe :writer_like? do
        it 'returns true for a writable file' do
          filename = File.join(tmpdir, 'out')

          File.open(filename, 'wb') do |out|
            expect(Files.writer_like?(out)).to eq(true)
          end
        end

        it 'returns true for a StringIO' do
          out = StringIO.new
          expect(Files.writer_like?(out)).to eq(true)
        end

        it 'returns true for a Tempfile' do
          out = Tempfile.new('out')
          begin
            expect(Files.writer_like?(out)).to eq(true)
          ensure
            out.close
            out.unlink
          end
        end

        it 'returns false for something that is not writer-like' do
          expect(Files.writer_like?('not an IO')).to eq(false)
        end
      end
    end
  end
end
