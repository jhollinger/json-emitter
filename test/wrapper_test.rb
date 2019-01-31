require 'test_helper'

class WrapperTest < Minitest::Test
  def test_one_wrap
    log = []
    emitter = JsonEmitter::Emitter.new
    emitter.context.wrap do
      ->(next_wrapper) {
        log << "Before"
        x = next_wrapper.call
        log << "Got Enumerator::Yielder"
        log << "After"
        x
      }
    end

    result = emitter.array(Enumerator.new { |y|
      log << "Getting 1"
      y << 1
      log << "Getting 2"
      y << 2
      log << "Getting 3"
      y << 3
    }).reduce('') { |a, data|
      a + data
    }

    assert_equal "[1,2,3]", result
    assert_equal [
      "Before",
      "Getting 1",
      "Getting 2",
      "Getting 3",
      "Got Enumerator::Yielder",
      "After"
    ], log
  end

  def test_two_wraps
    log = []
    emitter = JsonEmitter::Emitter.new
    emitter.context.wrap do
      ->(next_wrapper) {
        log << "Before (outer)"
        x = next_wrapper.call
        log << "Got Enumerator::Yielder"
        log << "After (outer)"
        x
      }
    end

    emitter.context.wrap do 
      ->(next_wrapper) {
        log << "Before (inner)"
        x = next_wrapper.call
        log << "Got Enumerator::Yielder"
        log << "After (inner)"
        x
      }
    end

    result = emitter.array(Enumerator.new { |y|
      log << "Getting 1"
      y << 1
      log << "Getting 2"
      y << 2
      log << "Getting 3"
      y << 3
    }).reduce('') { |a, data|
      a + data
    }

    assert_equal "[1,2,3]", result
    assert_equal [
      "Before (outer)",
      "Before (inner)",
      "Getting 1",
      "Getting 2",
      "Getting 3",
      "Got Enumerator::Yielder",
      "After (inner)",
      "Got Enumerator::Yielder",
      "After (outer)",
    ], log
  end

  def test_handles_error_in_enumerator
    log, errors = [], []

    emitter = JsonEmitter::Emitter.new
    emitter.context.error do |e|
      errors << e.message
    end

    enum = Enumerator.new { |y|
      y << 1
      y << 2
      raise "Can't do 3"
      y << 3
    }

    stream = emitter.array(enum) { |n|
      log << n
      n
    }

    begin
      stream.reduce { |a, n| a + n }
    rescue
    end
    assert_equal [1, 2], log
    assert_equal ["Can't do 3"], errors
  end

  def test_handles_error_in_mapper
    log, errors = [], []

    emitter = JsonEmitter::Emitter.new
    emitter.context.error do |e|
      errors << e.message
    end

    enum = Enumerator.new { |y|
      y << 1
      y << 2
      y << 3
    }

    stream = emitter.array(enum) { |n|
      raise "Can't do 3" if n == 3
      log << n
      n
    }

    begin
      stream.reduce { |a, n| a + n }
    rescue
    end
    assert_equal [1, 2], log
    assert_equal ["Can't do 3"], errors
  end

  def test_handles_error_in_each
    errors = []
    emitter = JsonEmitter::Emitter.new
    emitter.context.error do |e|
      errors << e.message
    end

    enum = Enumerator.new { |y|
      y << 1
      y << 2
      y << 3
    }

    i = 0
    begin
      emitter.array(enum).each { |chunk|
        i += 1
        raise "Can't do 3"
      }
    rescue
    end

    assert_equal ["Can't do 3"], errors
  end
end
