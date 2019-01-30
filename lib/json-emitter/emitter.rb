module JsonEmitter
  #
  # Builds Enumerators that yield JSON from Ruby Arrays or Hashes.
  #
  class Emitter
    def initialize
      @wrappers = JsonEmitter.wrappers.map(&:call).compact
      @error_handlers = JsonEmitter.error_handlers
      @pass_through_errors = []
      @pass_through_errors << Puma::ConnectionError if defined? Puma::ConnectionError
    end

    #
    # Generates an Enumerator that will stream out a JSON array.
    #
    # @param enum [Enumerable] Something that can be enumerated over, like an Array or Enumerator. Each element should be something that can be rendered as JSON (e.g. a number, string, boolean, Array, or Hash).
    # @yield If a block is given, it will be yielded each value in the array. The return value from the block will be converted to JSON instead of the original value.
    # @return [Enumerator]
    #
    def array(enum, &mapper)
      Enumerator.new { |y|
        wrapped {
          array_generator(enum, &mapper).each { |json_val|
            y << json_val
          }
        }
      }
    end

    #
    # Generates an Enumerator that will stream out a JSON object.
    #
    # @param hash [Hash] Keys should be Strings or Symbols and values should be any JSON-compatible value like a number, string, boolean, Array, or Hash.
    # @return [Enumerator]
    #
    def object(hash)
      Enumerator.new { |y|
        wrapped {
          object_generator(hash).each { |json_val|
            y << json_val
          }
        }
      }
    end

    # Wrap the enumeration in a block. It will be passed a callback which it must call to continue.
    # TODO better docs and examples.
    def wrap(&block)
      if (wrapper = block.call)
        @wrappers.unshift wrapper
      end
    end

    # Add an error handler.
    # TODO better docs and examples.
    def error(&handler)
      @error_handlers += [handler]
    end

    private

    def array_generator(enum, &mapper)
      Enumerator.new { |y|
        y << "[".freeze

        first = true
        enum.each { |val|
          y << ",".freeze unless first
          first = false if first

          mapped_val = mapper ? mapper.call(val) : val
          json_values(mapped_val).each { |json_val|
            y << json_val
          }
        }

        y << "]".freeze
      }
    end

    def object_generator(hash)
      Enumerator.new { |y|
        y << "{".freeze

        first = true
        hash.each { |key, val|
          y << ",".freeze unless first
          first = false if first

          json_key = MultiJson.dump(key.to_s)
          y << "#{json_key}:"

          json_values(val).each { |json_val|
            y << json_val
          }
        }

        y << "}".freeze
      }
    end

    def json_values(x)
      case x
      when Hash
        object_generator x
      when Enumerable
        array_generator x
      when Proc
        y = x.call
        json_values y
      else
        [MultiJson.dump(x)]
      end
    end

    def wrapped(&final)
      @wrappers.reduce(final) { |f, outer_wrapper|
        ->() { outer_wrapper.call(f) }
      }.call

    rescue *@pass_through_errors => e
      raise e
    rescue => e
      @error_handlers.each { |h| h.call(e) }
      raise e
    end
  end
end
