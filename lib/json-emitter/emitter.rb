module JsonEmitter
  #
  # Builds Enumerators that yield JSON from Ruby Arrays or Hashes.
  #
  class Emitter
    #
    # Generates an Enumerator that will stream out a JSON array.
    #
    # @param enum [Enumerable] Something that can be enumerated over, like an Array or Enumerator. Each element should be something that can be rendered as JSON (e.g. a number, string, boolean, Array, or Hash).
    # @yield If a block is given, it will be yielded each value in the array. The return value from the block will be converted to JSON instead of the original value.
    # @return [Enumerator]
    #
    def array(enum, &mapper)
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

    #
    # Generates an Enumerator that will stream out a JSON object.
    #
    # @param hash [Hash] Keys should be Strings or Symbols and values should be any JSON-compatible value like a number, string, boolean, Array, or Hash.
    # @return [Enumerator]
    #
    def object(hash)
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

    private

    def json_values(x)
      case x
      when Hash then object x
      when Enumerable then array x
      when Proc
        y = x.call
        json_values y
      else [MultiJson.dump(x)]
      end
    end
  end
end
