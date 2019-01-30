require 'test_helper'

class ObjectEmitterTest < Minitest::Test
  def test_simple_object
    hash = {
      a: 1,
      b: 2,
      c: 3,
    }

    stream = JsonEmitter::Emitter.new.object(hash)
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
    ), stream.reduce([]) { |a, str| a << str }
  end

  def test_enumerated_objects
    order_enum = Enumerator.new { |y|
      y << {id: 1, name: "A"}
      y << {id: 2, name: "B"}
      y << {id: 3, name: "C"}
    }
    hash = {
      orders: order_enum,
      date: Date.new(2019, 1, 29),
    }

    stream = JsonEmitter::Emitter.new.object(hash)
    assert_equal %w(
      {
        "orders":
        [
          {
            "id":
            1
            ,
            "name":
            "A"
          }
          ,
          {
            "id":
            2
            ,
            "name":
            "B"
          }
          ,
          {
            "id":
            3
            ,
            "name":
            "C"
          }
        ]
        ,
        "date":
        "2019-01-29"
      }
    ), stream.reduce([]) { |a, str| a << str }
  end

  def test_proc_objects
    hash = {
      text1: ->() {
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
      },
      text2: ->() {
        "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?"
      }
    }

    stream = JsonEmitter::Emitter.new.object(hash)
    assert_equal [
      %({),
      %("text1":),
      %("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."),
      %(,),
      %("text2":),
      %("Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?"),
      %(}),
    ], stream.reduce([]) { |a, str| a << str }
  end
end
