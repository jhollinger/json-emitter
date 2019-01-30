require 'test_helper'

class StreamTest < Minitest::Test
  def setup
    @enum = enum = Enumerator.new { |y|
      y << 1
      y << 2
      y << 3
      y << "a"
      y << "b"
      y << "c"
      y << true
      y << false
      y << nil
      y << Date.new(2019, 1, 29)
    }
  end

  def test_write
    stream = JsonEmitter.array(@enum)
    io = StringIO.new
    stream.write io
    io.rewind
    assert_equal %q|[1,2,3,"a","b","c",true,false,null,"2019-01-29"]|, io.read
  end

  def test_each_with_block
    output = []
    stream = JsonEmitter.array(@enum).unbuffered
    stream.each do |str|
      output << str
    end
    assert_equal %w(
      [
        1
        ,
        2
        ,
        3
        ,
        "a"
        ,
        "b"
        ,
        "c"
        ,
        true
        ,
        false
        ,
        null
        ,
        "2019-01-29"
      ]
    ), output
  end

  def test_each_without_block
    stream = JsonEmitter.array(@enum).unbuffered
    output = stream.reduce([]) do |a, str|
      a << str
    end
    assert_equal %w(
      [
        1
        ,
        2
        ,
        3
        ,
        "a"
        ,
        "b"
        ,
        "c"
        ,
        true
        ,
        false
        ,
        null
        ,
        "2019-01-29"
      ]
    ), output
  end

  def test_buffered_write
    stream = JsonEmitter.array(@enum, buffer_size: 4, buffer_unit: :bytes)
    io = StringIO.new
    stream.write io
    io.rewind
    assert_equal %q|[1,2,3,"a","b","c",true,false,null,"2019-01-29"]|, io.read
  end

  def test_buffered_each_with_block
    output = []
    stream = JsonEmitter.array(@enum, buffer_size: 4, buffer_unit: :bytes)
    stream.each do |str|
      output << str
    end
    assert_equal [
      %([1,2),
      %(,3,"a"),
      %(,"b"),
      %(,"c"),
      %(,true),
      %(,false),
      %(,null),
      %(,"2019-01-29"),
      %(])
    ], output
  end

  def test_buffered_each_without_block
    stream = JsonEmitter.array(@enum, buffer_size: 4, buffer_unit: :bytes)
    output = stream.reduce([]) do |a, str|
      a << str
    end
    assert_equal [
      %([1,2),
      %(,3,"a"),
      %(,"b"),
      %(,"c"),
      %(,true),
      %(,false),
      %(,null),
      %(,"2019-01-29"),
      %(])
    ], output
  end
end
