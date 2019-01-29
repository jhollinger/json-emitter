require 'test_helper'

class ObjectTest < Minitest::Test
  def setup
    @hash = {
      a: 1,
      b: 2,
      c: 3,
    }
  end

  def test_write
    stream = JsonEmitter.object(@hash)
    io = StringIO.new
    stream.write io
    io.rewind
    assert_equal %q|{"a":1,"b":2,"c":3}|, io.read
  end

  def test_each
    stream = JsonEmitter.object(@hash)
    output = stream.reduce([]) do |a, str|
      a << str
    end
    assert_equal %w(
      {
        "a":
        1
        ,
        "b":
        2
        ,
        "c":
        3
      }
    ), output
  end

  def test_buffered_each
    stream = JsonEmitter.object(@hash).buffered(4, unit: :bytes)
    output = stream.reduce([]) do |a, str|
      a << str
    end
    assert_equal [
      %({"a":),
      %(1,"b":),
      %(2,"c":),
      %(3}),
    ], output
  end
end
