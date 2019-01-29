require 'test_helper'

class StreamTest < Minitest::Test
  def test_write
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

    stream = JsonEmitter.array(enum)
    io = StringIO.new
    stream.write io
    io.rewind
    assert_equal %q|[1,2,3,"a","b","c",true,false,null,"2019-01-29"]|, io.read
  end
end
