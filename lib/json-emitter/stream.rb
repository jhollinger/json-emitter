module JsonEmitter
  #
  # Represents a stream of JSON to be generated and yielded. It can be treated like any Enumerable.
  # Unlike UnbufferedStream, the size of the yielded strings can vary from 1 to 1000's.
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
