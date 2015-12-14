require 'forwardable'
require 'cucumber/core/platform'
module Cucumber
  module Core
    module Ast
      module Location
        WILDCARD = :*

        def self.of_caller(additional_depth = 0)
          from_file_colon_line(*caller[1 + additional_depth])
        end

        def self.from_file_colon_line(file_colon_line)
          file, raw_line = file_colon_line.match(/(.*):(\d+)/)[1..2]
          from_source_location(file, raw_line.to_i)
        end

        def self.from_source_location(file, line)
          file = File.expand_path(file)
          pwd = File.expand_path(Dir.pwd)
          pwd.force_encoding(file.encoding)
          if file.index(pwd)
            file = file[pwd.length+1..-1]
          elsif file =~ /.*\/gems\/(.*\.rb)$/
            file = $1
          end
          new(file, line)
        end

        def self.new(file, raw_lines=nil)
          file || raise(ArgumentError, "file is mandatory")
          if raw_lines
            Precise.new(file, Lines.new(raw_lines))
          else
            Wildcard.new(file)
          end
        end

        class Wildcard < Struct.new(:file)
          def to_s
            file
          end

          def match?(other)
            other.file == file
          end

          def include?(lines)
            true
          end
        end

        class Precise < Struct.new(:file, :lines)
          def include?(other_lines)
            lines.include?(other_lines)
          end

          def line
            lines.first
          end

          def match?(other)
            return false unless other.file == file
            other.include?(lines)
          end

          def to_s
            [file, lines.to_s].join(":")
          end

          def hash
            self.class.hash ^ to_s.hash
          end

          def to_str
            to_s
          end

          def on_line(new_line)
            Location.new(file, new_line)
          end

          def inspect
            "<#{self.class}: #{to_s}>"
          end
        end

        require 'set'
        class Lines < Struct.new(:data)
          protected :data

          def initialize(raw_data)
            super Array(raw_data).to_set
          end

          def first
            data.first
          end

          def include?(other)
            other.data.subset?(data) || data.subset?(other.data)
          end

          def to_s
            boundary.join('..')
          end

          def inspect
            "<#{self.class}: #{to_s}>"
          end

          protected

          def boundary
            first_and_last(value).uniq
          end

          def at_index(idx)
            data.to_a[idx]
          end

          def value
            method :at_index
          end

          def first_and_last(something)
            [0, -1].map(&something)
          end
        end
      end

      module HasLocation
        def file_colon_line
          location.to_s
        end

        def file
          location.file
        end

        def line
          location.line
        end

        def location
          raise('Please set @location in the constructor') unless defined?(@location)
          @location
        end

        def locations
          @locations ||= ([location] + attributes.map { |node| node.locations }).flatten
        end

        def attributes
          [tags, comments, multiline_arg].flatten
        end

        def tags
          # will be overriden by nodes that actually have tags
          []
        end

        def comments
          # will be overriden by nodes that actually have comments
          []
        end

        def multiline_arg
          # will be overriden by nodes that actually have a multiline_argument
          EmptyMultilineArgument.new
        end

      end
    end
  end
end
