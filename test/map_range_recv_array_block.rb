# `infer_method_name_type` for `map` used to fall through to
# `infer_type(recv)` when the block returned a non-trivial shape
# (an array literal). For a Range recv that yielded `range`,
# poisoning any ivar holding the result; an `@x = something_else`
# assignment then failed to type-check (`@x = 0` against an
# `sp_Range` slot).
#
# Now `Range#map { array_block }` infers as `<inner>_ptr_array`
# (matching the runtime sp_PtrArray storage), so the result can
# be indexed `arr[i][j]` directly. A subsequent re-assignment
# with a different array shape goes to a separate slot to avoid
# spinel's slot widening to poly.

class C
  def initialize
    # Block returns an int_array — outer is int_array_ptr_array.
    @rows = (0...3).map { |i| [i, i * 10] }
    # Separate slot for a plain int_array.
    @flat = [10, 20, 30]
  end

  def show
    @rows.each { |row| row.each { |v| puts v } }
    @flat.each { |v| puts v }
  end
end

C.new.show
# Expected:
#   0 / 0 / 1 / 10 / 2 / 20 (each row's elements)
#   10 / 20 / 30 (flat)
