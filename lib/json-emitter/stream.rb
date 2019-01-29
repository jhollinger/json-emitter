module JsonEmitter
  #
  # Represents a stream of JSON to be generated and yielded. It can be treated like any Enumerable.
  # The size of the yielded strings can vary from 1 to 1000's. If that's a problem, call JsonEmitter::Stream.buffer.
  #
  class Stream
    include Enumerable

    #
    # Initialize a new stream.
    #
    # @param enum [Enumerator] An enumerator that yields pieces of JSON.
    #
    def initialize(enum)
      @enum = enum
    end

    #
    # Returns a new stream that will buffer the output. You can perform the same "write" or "each" operations
    # on the new stream, but the chunks of output will be (roughly) uniform in size.
    #
    # @param buffer_size [Integer] The buffer size in kb. This is a size *hint*, not a hard limit.
    # @return [JsonEmitter::BufferedStream]
    #
    def buffered(buffer_size = 16)
      BufferedStream.new(@enum, buffer_size)
    end

    #
    # Write the stream to the specified IO object.
    #
    # @param io [IO]
    #
    def write(io)
      each { |str|
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
        @enum.each { |str|
          yield str
        }
      else
        @enum
      end
    end
  end
end
