# Issue #235 follow-up to #234: chained `@a = @b = expr` only widened
# the chain *head*. The tail (and intermediate participants in
# longer chains) relied on scan_ivars's dual-definite-literal gate,
# which fires for literal RHS but not for CallNode/expression RHS.
# A `@a = @b = make_int` with `@a`/`@b` previously string-typed left
# `@b`'s slot at `const char *` while compile_chained_ivar_writes
# emitted `iv_b = _t1;` with `_t1 : mrb_int`. Same C error shape
# #234 was fixing for the head, just on the tail.

class C
  def initialize
    @a = "hello"
    @b = "world"
  end

  def make_int
    42
  end

  # CallNode RHS — bypasses scan_ivars's literal-gate widening so
  # the chain-drill path is the only thing that can widen `@b`.
  def reset_call
    @a = @b = make_int
  end

  # 3-chain with CallNode RHS — every intermediate must widen.
  def reset_three(c)
    @a = @b = @c = c.length
  end

  def show
    puts @a
    puts @b
  end
end

c = C.new
c.reset_call
c.show                  # 42 / 42

c2 = C.new
c2.reset_three("ab")
c2.show                 # 2 / 2

# 3-chain that adds an `@c` slot to the picture too. After
# reset_three sets @c, calling show wouldn't read it (no accessor),
# but the struct emit needs to type-check.
puts "ok"
