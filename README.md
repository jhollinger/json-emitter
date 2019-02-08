# JsonEmitter [![Build Status](https://travis-ci.org/jhollinger/json-emitter.svg?branch=master)](https://travis-ci.org/jhollinger/json-emitter)

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
    self.response_body = JsonEmitter.array(enumerator) { |order|
      order.to_h
    }
  end
end
```

**Sinatra**

```ruby
get "/orders" do
  content_type :json
  JsonEmitter.array(enumerator) { |order|
    order.to_h
  }
end
```

**Grape**

```ruby
get :orders do
  stream JsonEmitter.array(enumerator) { |order|
    ApiV1::Entities::Order.new(order)
  }
end
```

**Rack**

```ruby
app = ->(env) {
  stream = JsonEmitter.array(enumerator) { |order|
    order.to_h
  }
  [200, {"Content-Type" => "application/json"}, stream]
}
```

# Other uses

`JsonEmitter.array` takes an `Enumerable` and returns a stream that generates chunks of JSON.

```ruby
JsonEmitter.array(enumerator).each { |json_chunk|
  # write json_chunk somewhere
}
```

`JsonEmitter.object` takes a `Hash` and returns a stream that generates chunks of JSON. Hash values can be literals, Enumerators, Arrays, other Hashes, or Procs that return any of those. Hashes and arrays may be nested.

```ruby
JsonEmitter.object({
  orders: Order.find_each.lazy.map { |order|
    {id: order.id, desc: order.description}
  },

  big_text_1: ->() {
    load_tons_of_text
  },

  big_text_2: ->() {
    load_tons_of_text
  },
}).each { |json_chunk|
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
