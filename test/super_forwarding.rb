# Bare `super` (no args, no parens) inside a constructor parses as
# `ForwardingSuperNode`, not `SuperNode`. Without the
# ForwardingSuperNode case, the call to the parent's `initialize`
# was silently dropped — the parent's ivar setup never ran and the
# child object was left in a half-initialized state.

class Base
  def initialize(x)
    @x = x
    @y = x * 10
  end
end

class Child < Base
  attr_reader :x, :y, :z
  def initialize(x)
    super              # bare — forwards x to Base#initialize
    @z = x + 1
  end
end

c = Child.new(3)
puts c.x   # 3
puts c.y   # 30
puts c.z   # 4
