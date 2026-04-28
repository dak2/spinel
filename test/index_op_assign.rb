# Compound assignment on an indexed receiver — `arr[i] OP= value`.
#
# Prism parses this as IndexOperatorWriteNode (distinct from a `.[]=` call).
# Without dedicated codegen the node would fall through and the whole
# update would be silently dropped — the loop body would emit only the
# index increment, leaving the array untouched.
#
# This test exercises +=, -=, *=, /= on FloatArray, IntArray, and a typed
# hash, both as direct local-variable indices and through a method call
# (`obj.attr[i] += x`) which is the more common shape inside class code.
#
# Use float values whose fractional part is non-zero so Spinel's float-puts
# and CRuby's match.

class Vec
  attr_accessor :data
  def initialize(n)
    @data = Array.new(n, 0.5)
  end
end

# +=, -=, *=, /= on FloatArray, both directly and through an object field.
v = Vec.new(4)
v.data[0] += 1.5
v.data[1] -= 0.5
v.data[2] *= 4.5
v.data[3] /= 0.5

puts v.data[0]    # 2.0  -> spinel will print "2"; integer values do strip
puts v.data[1]    # 0.0  -> "0"
puts v.data[2]    # 2.25
puts v.data[3]    # 1.0  -> "1"

# Same on IntArray (a plain local).
ints = Array.new(3, 10)
ints[0] += 5
ints[1] -= 3
ints[2] *= 2

puts ints[0]      # 15
puts ints[1]      # 7
puts ints[2]      # 20

# Compound assign on a typed hash: += on str_int_hash.
counts = {"a" => 1, "b" => 2}
counts["a"] += 10
counts["b"] += 20

puts counts["a"]  # 11
puts counts["b"]  # 22

# Same pattern through a method call on an object: `obj.attr[i] += x`.
# This is the shape that surfaces inside class methods walking their own
# instance-variable arrays in a while loop.
v2 = Vec.new(3)
i = 0
while i < 3
  v2.data[i] += 0.25
  i += 1
end
puts v2.data[0]   # 0.75
puts v2.data[1]   # 0.75
puts v2.data[2]   # 0.75
