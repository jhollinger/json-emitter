require 'test_helper'

class ArrayEmitterTest < Minitest::Test
  def test_simple_array
    enum = Enumerator.new { |y|
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

    emitter = JsonEmitter::Emitter.new.array(enum)
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
    ), emitter.reduce([]) { |a, str| a << str }
  end

  def test_mapped_array
    enum = Enumerator.new { |y|
      y << 1
      y << 2
      y << 3
    }

    emitter = JsonEmitter::Emitter.new.array(enum) { |n|
      n * 2
    }
    assert_equal %w(
      [
        2
        ,
        4
        ,
        6
      ]
    ), emitter.reduce([]) { |a, str| a << str }
  end

  def test_nested_arrays
    enum = Enumerator.new { |y|
      y << 1
      y << Enumerator.new { |y2|
        y2 << "a"
        y2 << "b"
        y2 << "c"
        y2 << Enumerator.new { |y3|
          y3 << true
          y3 << false
        }
        y2 << "d"
      }
      y << ["foo", "bar"]
      y << 2
    }

    emitter = JsonEmitter::Emitter.new.array(enum)
    assert_equal %w(
    [
      1
      ,
      [
        "a"
        ,
        "b"
        ,
        "c"
        ,
        [
          true
          ,
          false
        ]
        ,
        "d"
      ]
      ,
      [
        "foo"
        ,
        "bar"
      ]
      ,
      2
    ]
    ), emitter.reduce([]) { |a, str| a << str }
  end
end
