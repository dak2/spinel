# `@a = obj.attr = val` and similar chains used to mistype the
# outer LHS. `infer_call_type` had no special case for an
# attr-writer CallNode (`obj.attr = val`), so it fell through to
# the int default. Codegen was emitting the right C-level
# assignment expression `(rc->iv_attr = arg)` (which evaluates
# to the rhs in C), but the surrounding LHS was declared as
# `mrb_int`, so `outer = (rc->iv_attr = obj_value)` typed the
# outer slot as int and any later use went through the wrong
# dispatch.
#
# Fix: when `infer_call_type` sees a CallNode whose name ends
# with `=` (and isn't `==` / `<=` / etc.), and the receiver is
# obj-typed and has an attr_writer for the slot, return the rhs
# argument's type. Ruby semantics: an assignment expression
# evaluates to the rhs.

class Box
  def initialize(n); @n = n; @arr = []; @arr << n; end
  attr_reader :n
end

class Holder
  attr_writer :box
end

# Simple chain — the result of `h.box = Box.new(...)` should be
# a Box, not an int.
h = Holder.new
b = (h.box = Box.new(42))
puts b.n   # 42

# Optcarrot-shape chain: `@a = obj.x = expr`. Both `@a` and
# `obj.x` get the same Box; reading either back gives the
# same value.
class Apu
  def initialize(n); @n = n; @arr = []; @arr << n; end
  attr_reader :n
end

class Cpu
  attr_writer :apu
  attr_reader :apu
end

class Nes
  def initialize
    @cpu = Cpu.new
    @apu = @cpu.apu = Apu.new(99)
  end
  attr_reader :apu, :cpu
end

n = Nes.new
puts n.apu.n        # 99
puts n.cpu.apu.n    # 99
