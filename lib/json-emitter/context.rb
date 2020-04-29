module JsonEmitter
  #
  # By using JsonEmitter.wrap and JsonEmitter.error you can wrap your streams within a special "context".
  #
  # This is probably most useful when your stream is being consumed by Rack/Rails/Sinatra/Grape/etc. Your
  # app is probably depending on certain Rack middlewars to provide before/after behavior and error handling.
  # All those middlewares will over by the time Rack consumes your stream, but you can use JsonEmitter.wrap
  # and JsonEmitter.error to add critical behavior back in.
  #
  class Context
    # @return [Hash] The Rack environment Hash (if present)
    attr_reader :rack_env

    def initialize(rack_env: nil)
      @rack_env = rack_env
      @wrappers = JsonEmitter.wrappers.map(&:call).compact
      @error_handlers = JsonEmitter.error_handlers
      @pass_through_errors = []
      @pass_through_errors << Puma::ConnectionError if defined? Puma::ConnectionError
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

    # Returns a Rack::Request from rack_env (if rack_env was given).
    def request
      if rack_env
        @request ||= Rack::Request.new(rack_env)
      end
    end

    # Execute a block within this context.
    def execute(&inner)
      @wrappers.reduce(inner) { |f, outer_wrapper|
        ->() { outer_wrapper.call(f) }
      }.call

    rescue *@pass_through_errors => e
      raise e
    rescue => e
      @error_handlers.each { |h| h.call(e, self) }
      raise e
    end
  end
end
