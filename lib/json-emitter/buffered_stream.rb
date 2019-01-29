module JsonEmitter
  #
  # Represents a stream of JSON to be generated and yielded. It can be treated like any Enumerable.
  # Unlike JsonEmitter::Stream, the yielded output is buffered into (roughly) equally sized chunks.
  #
  class BufferedStream
    include Enumerable

    #
    # Initialize a new buffered stream.
    #
    # @param enum [Enumerator] An enumerator that yields pieces of JSON.
    # @param buffer_size [Integer] The buffer size in kb. This is a size *hint*, not a hard limit.
    #
    def initialize(enum, buffer_size)
      @enum = enum
      @buffer_size = buffer_size
    end

    #
    # Write the stream to the specified IO object.
    #
    # @param io [IO]
    #
    def write(io)
      buffer.each { |str|
        io << str
      }
    end

    #
    # If a block is given, each chunk of JSON is yielded to it. If not block is given, an Enumerator is returned.
    #
    # @return [Enumerator]
    #
    def each
      if block_given?
        buffer.each { |str|
          yield str
        }
      else
        buffer
      end
    end

    private

    def buffer
      Enumerator.new { |y|
        buff = ""
        @enum.each { |str|
          buff << str
          if buff.bytesize >= @buffer_size
            y << buff
            buff = ""
          end
        }
        y << buff unless buff.empty?
      }
    end
  end
end
