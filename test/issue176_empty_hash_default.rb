# Issue #176: empty-Hash default parameter `def m(h = {})` used to
# silently corrupt the caller-supplied Hash because unify_call_types
# widened the param type to "poly" and the poly dispatch tree had no
# arm for SymIntHash/StrIntHash. Hash variants now escalate the
# str_int_hash empty default to the call-site type, mirroring the
# int_array → typed-array escalation.

class A
  def initialize(attrs = {})
    @x = attrs[:x]
  end
  def x; @x; end
end

puts A.new({x: 42}).x

class B
  def initialize(attrs = {})
    @name = attrs[:name]
  end
  def name; @name; end
end

puts B.new({name: "alice"}).name

# String-keyed hash also works.
class C
  def initialize(attrs = {})
    @v = attrs["v"]
  end
  def v; @v; end
end

puts C.new({"v" => 7}).v
