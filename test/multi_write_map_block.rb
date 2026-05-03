# `A, B = arr.map { block }` is destructuring assignment where
# each LHS target receives one element of the mapped array.
# Two related codegen pieces need to land together:
#
# 1. Type inference for the target slot. When the block returns a
#    typed array (e.g. int_array), the target must be typed
#    accordingly. Without the fix, the outer `infer_type` collapses
#    array-of-array to the int_array placeholder and every target
#    comes out as int.
#
# 2. Code emission for constant targets when the RHS evaluates to
#    a ptr_array. Without the fix, the multi-write codegen had
#    branches for ArrayNode literal RHS and int_array RHS but no
#    ptr_array branch — every constant target stayed unset.

class C
  # Outer map produces a ptr_array (each element is an int_array
  # produced by the inner map).
  P, Q = [3, 5].map { |n| (0...n).to_a }
end

# Without the inference fix, P and Q would be typed `int` and the
# `.length` / `[]` calls below wouldn't compile against the real
# `sp_IntArray *` values stored in them.
puts C::P.length   # 3
puts C::P[0]       # 0
puts C::P[1]       # 1
puts C::P[2]       # 2
puts C::Q.length   # 5
puts C::Q[3]       # 3
puts C::Q[4]       # 4
