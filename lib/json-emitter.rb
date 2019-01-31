require 'multi_json'

require 'json-emitter/version'
require 'json-emitter/context'
require 'json-emitter/emitter'
require 'json-emitter/stream'
require 'json-emitter/buffered_stream'

#
# Efficiently generate very large strings of JSON from Ruby objects.
#
# Complex values like arrays and objects may be as large and nested as you need without compromising efficiency.
# Primitive values will be serialized to JSON using MultiJson.dump. MultiJson finds and uses the most efficient
# JSON generator you have on your system (e.g. oj) and falls back to the stdlib JSON library.
#
# The emitter can be used to output to anything (files, network sockets, etc). It works very well with so-called
# "HTTP chunked responses" in Rack/Rails/Sinatra/Grape/etc.
#
module JsonEmitter
  class << self
    attr_reader :wrappers
    attr_reader :error_handlers
  end
  @wrappers = []
  @error_handlers = []

  #
  # Generates a stream that will output a JSON array. The input can be any Enumerable, such as an Array or an Enumerator.
  #
  # The following example uses minumum memory to genrate a very large JSON array string from an ActiveRecord query.
  # Only 500 Order records will ever by in memory at once. The JSON will be generated in small chunks so that
  # the whole string is never in all memory at once.
  #
  #   enumerator = Order.limit(10_000).find_each(batch_size: 500)
  #   stream = JsonEmitter.array(enumerator) { |order|
  #     {
  #       number: order.id,
  #       desc: order.description,
  #       ...
  #     }
  #   }
  #
  #   # generate the JSON in chunks and write them to STDOUT
  #   stream.write($stdout)
  #
  #   # generate chunks of JSON and do something with them
  #   stream.each do |json_chunk|
  #     # do something with each json chunk
  #   end
  #
  # @param enum [Enumerable] Something that can be enumerated over, like an Array or Enumerator. Each element should be something that can be rendered as JSON (e.g. a number, string, boolean, Array, or Hash).
  # @param buffer_size [Integer] The buffer size in kb. This is a size *hint*, not a hard limit.
  # @param buffer_unit [Symbol] :bytes | :kb (default) | :mb
  # @yield If a block is given, it will be yielded each value in the array. The return value from the block will be converted to JSON instead of the original value.
  # @return [JsonEmitter::BufferedStream]
  #
  def self.array(enum, buffer_size: 16, buffer_unit: :kb, &mapper)
    emitter = Emitter.new.array(enum, &mapper)
    BufferedStream.new(emitter, buffer_size, unit: buffer_unit)
  end

  #
  # Generates a stream that will output a JSON object.
  #
  # If some of the values will be large arrays, use Enumerators or lazy Enumerators to build each element on demand
  # (to potentially save lots of RAM).
  #
  # You can also use Procs to generate large arrays, objects, blocks of text, etc. They'll only be used one at
  # a time, which can potentially save lots of RAM.
  #
  # The following example generates a very large JSON object string from several components.
  #
  #   stream = JsonEmitter.object({
  #     time: Time.now.iso8601,
  #     is_true: true,
  #     orders: Order.limit(10_000).find_each(batch_size: 500).lazy.map { |order|
  #       {number: order.id, desc: order.description}
  #     },
  #     high_mem_thing_1: ->() {
  #       get_high_mem_thing1()
  #     },
  #     high_mem_thing_2: ->() {
  #       get_high_mem_thing2()
  #     },
  #   })
  #
  #   # generate the JSON in chunks and write them to STDOUT
  #   stream.write($stdout)
  #
  #   # generate chunks of JSON and do something with them
  #   stream.each do |json_chunk|
  #     # do something with each json chunk
  #   end
  #
  # @param hash [Hash] Keys should be Strings or Symbols and values should be any JSON-compatible value like a number, string, boolean, Array, or Hash.
  # @param buffer_size [Integer] The buffer size in kb. This is a size *hint*, not a hard limit.
  # @param buffer_unit [Symbol] :bytes | :kb (default) | :mb
  # @return [JsonEmitter::BufferedStream]
  #
  def self.object(hash, buffer_size: 16, buffer_unit: :kb)
    emitter = Emitter.new.object(hash)
    BufferedStream.new(emitter, buffer_size, unit: buffer_unit)
  end

  # Wrap the enumeration in a Proc. It will be passed a callback which it must call to continue.
  # TODO better docs and examples.
  def self.wrap(&wrapper)
    @wrappers.unshift wrapper
  end

  # Add an error handler.
  # TODO better docs and examples.
  def self.error(&handler)
    @error_handlers << handler
  end
end
