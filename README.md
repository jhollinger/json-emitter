# JsonEmitter [![Build Status](https://travis-ci.org/jhollinger/json-emitter.svg?branch=master)](https://travis-ci.org/jhollinger/json-emitter)

*NOTE this project may appear inactive, but that's just because it's **done** (I think). Enjoy!*

JsonEmitter is a library for efficiently generating very large bits of JSON in Ruby. Need to generate a JSON array of 10,000 database records without eating up all your RAM? No problem! Objects? Nested structures? JsonEmitter has you covered.

Use JsonEmitter in your Rack/Rails/Sinatra/Grape API to stream large JSON responses without worrying (much) about RAM or HTTP timeouts. Use it to write large JSON objects to your filesystem, S3, or ~~a 3D printer~~ anywhere else!

# HTTP Chunked Responses

These examples will use the Order enumerator to generate chunks of JSON and send them to the client as more chunks are generated. No more than 500 orders will be in memory at a time, regardless of how many orders there are. And only small portions of the JSON will be in memory at once, no matter how much we're generating. (NOTE There **are** limits to how long something will stream - your app server, nginx/apache, your browser, etc. may cut it off eventually.)

```ruby
enumerator = Order.
  where("created_at >= ?", 1.year.ago).
  find_each(batch_size: 500)
```

**Rails**

```ruby
class OrdersController < ApplicationController
  def index
    headers["Content-Type"] = "application/json"
    headers["Last-Modified"] = Time.now.ctime.to_s
    self.response_body = JsonEmitter.array(enumerator, rack: env) { |order|
      order.to_h
    }
  end
end
```

**Sinatra**

```ruby
get "/orders" do
  content_type :json
  JsonEmitter.array(enumerator, rack: env) { |order|
    order.to_h
  }
end
```

**Grape**

```ruby
get :orders do
  stream JsonEmitter.array(enumerator, rack: env) { |order|
    ApiV1::Entities::Order.new(order)
  }
end
```

**Rack**

```ruby
app = ->(env) {
  stream = JsonEmitter.array(enumerator, rack: env) { |order|
    order.to_h
  }
  [200, {"Content-Type" => "application/json"}, stream]
}
```

## Sending objects

You may also stream Hashes as JSON objects. Keys must be Strings or Symbols, but values may be anything: literals, Enumerators, Arrays, other Hashes, or Procs that return any of those.

```ruby
JsonEmitter.object({
  orders: Order.find_each.lazy.map { |order|
    {id: order.id, desc: order.description}
  },
  big_text: ->() { load_tons_of_text },
}, rack: env)
```

## Rack middleware won't work!

**IMPORTANT** Your Rack middleware will be *finished* by the time your JSON is built! So if you're depending on middleware to set `Time.zone`, report exceptions, etc. it won't work here. Fortunately, you can use `JsonEmitter.wrap` and `JsonEmitter.error` as replacements.

Put these somewhere like `config/initializers/json_emitter.rb`.

### JsonEmitter.wrap

```ruby
# Ensure that ActiveRecord connections are returned to the connection pool
JsonEmitter.wrap do
  ->(app) { ActiveRecord::Base.with_connection(&app.call) }
end

JsonEmitter.wrap do
  # Get TZ at the call site
  current_tz = Time.zone
  
  # Return a Proc that restores the call site's TZ before building the JSON
  ->(app) {
    default_tz = Time.zone
    Time.zone = current_tz
    res = app.call
    Time.zone = default_tz
    res
  }
end
```

### JsonEmitter.error

```ruby
JsonEmitter.error do |ex, context|
  Airbrake.notify(ex, {
    request_path: context.request&.path,
    query_string: context.request&.query_string,
  })
end
```

## Returning errors

When streaming an HTTP response, you can't change the response code once you start sending data. So if you hit an error after you start, you need another way to communicate errors to the client.

One way is to always steam an object that includes an `errors` field. Any errors will be collected while the `Enumerator` is running. After it's finished, they'll be added to the JSON object.

```ruby
  def get_data
    errors = []
    enum = Enumerator.new { |y|
      finished = false
      until finished
        data, errs, finished = get_data_chunk
        if errs
          errors += errs
          finished = true
          next
        end
        data.each { x| y << x }
      end
    }
    return enum, -> { errors }
  end
  
  items_enum, errors_proc = get_data
  JsonEmitter.object({
    items: items_enum,
    errors: errors_proc,
  })
```

# Non-HTTP uses

`JsonEmitter.array` takes an `Enumerable` and returns a stream that generates chunks of JSON.

```ruby
JsonEmitter.array(enumerator).each { |json_chunk|
  # write json_chunk somewhere
}
```

Streams have a `#write` method for writing directly to a `File` or `IO` object.

```ruby
File.open("~/out.json", "w+") { |f|
  JsonEmitter.array(enumerator).write f
}
```

# License

MIT License. See LICENSE for details.

# Copyright

Copywrite (c) 2019 Jordan Hollinger.
