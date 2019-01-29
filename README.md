## JsonEmitter

### Work in progress!!

JsonEmitter is a library for efficiently generating very large chunks of JSON. Need to generate a JSON array of 10,000 database records without eating up all your RAM? No problem! Objects? Nested structures? JsonEmitter has you covered.

JsonEmitter works for any reasonable use case and then some. Use JsonEmitter in your Rack/Rails/Sinatra/Grape API to stream large JSON responses without worrying about RAM or HTTP timeouts. Use it to write large JSON objects to your filesystem, S3, or ~~a 3D printer~~ anything else!

JsonEmitter uses the `multi_json` gem which uses the fastest available JSON serializer on your system (e.g `oj`). If you haven't installed any specifically, Ruby's built-in JSON library is used.

### HTTP Chunked Transfer (a.k.a streaming)

In HTTP 1.0 the entire response is normally sent all at once. Usually this is fine, but it can cause problems when very large responses must be generated and sent. These problems usually manifest as spikes in memory usage and/or responses that take so long to send that the client (or an in-between proxy) times out the request.

The solution to this in HTTP 1.1 is chunked transfer encoding. The response body can be split up and sent in a series of separate "chunks" for the client to receive and automatically put back together. Ruby's Rack specification supports chunking, as do most frameworks based on it (e.g. Rails, Sinatra, Grape, etc).

The following examples all show the same streaming API in various Rack-based frameworks. Without streaming this API could eat up tons of memory, take too long, and time out on the client. With streaming, the following improvements are possible, all without your client-side code needing any changes:

1. Only 500 orders will ever be in memory at once.
2. Only one `ApiV1::Entities::Order` will ever be in memory at once.
3. Only 16kb (roughly) of JSON will ever be in memory at once.
5. That 16kb of JSON will be sent to the client while the next 16kb of JSON is generating.

**IMPORTANT** Not every Ruby application server supports HTTP chunking. Puma definitely supports it and WEBrick definitely does not. Phusion Passenger claims to but I have not tried it.

#### Rails

TODO

#### Sinatra

TODO

#### Grape

```ruby
get :orders do
  enumerator = Order.
    where("created_at >= ?", 1.year.ago).
    find_each(batch_size: 500)

  stream JsonEmitter.array(enumerator) { |order|
    ApiV1::Entities::Order.new(order)
  }.buffered(16)
end
```

#### Rack

```ruby
app = ->(env) {
  enumerator = Order.
    where("created_at >= ?", 1.year.ago).
    find_each(batch_size: 500)

  stream = JsonEmitter.array(enumerator) { |order|
    order.to_h
  }.buffered(16)

  [200, {"Content-Type" => "application/json"}, stream]
}
```
