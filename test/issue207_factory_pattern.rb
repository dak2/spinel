# Issue #207: factory class method (`def self.from_raw`) using
# implicit `new`, calling a setter on the new instance whose value
# came from a poly-hash-returning fetch. Several composing gaps:
#
#   1. Bare `new` inside a `def self.<m>` body must resolve to
#      <CurrentClass>.new (returning obj_<CurrentClass>).
#   2. The class method's parameter type must widen from the
#      class-constant call site (`T.from_raw(p)` → params: obj_P).
#   3. The setter's poly arg must widen the receiving ivar's slot
#      type (sp_RbVal field, not mrb_int).
#   4. The fetch's nil-default param must widen from the call-site
#      string default ("" → string?).

class P
  def initialize(h)
    @h = h
  end
  def fetch(key, default = nil)
    return @h[key] if @h.key?(key)
    default
  end
end

class T
  attr_accessor :title
  def self.from_raw(params)
    instance = new
    instance.title = params.fetch(:title, "")
    instance
  end
end

p = P.new({title: "hello", count: 42})
t = T.from_raw(p)
puts t.title
