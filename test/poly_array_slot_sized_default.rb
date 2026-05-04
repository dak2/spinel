# `@arr = [nil] * N` going into a poly_array slot used to lower
# the rhs via the default `*` codegen, which produces an sp_IntArray.
# The slot is `sp_PolyArray *` (widened by writer-scan via
# heterogeneous `@arr[i] = v` writes elsewhere in the class), so
# the resulting C contains a pointer-type mismatch:
#
#   sp_IntArray *_t1 = sp_IntArray_new();
#   ...
#   self->iv_arr = _t1;          /* iv_arr is sp_PolyArray * */
#
# The default `-Wno-all` build silently coerces and the runtime
# runs with garbage: subsequent `sp_PolyArray_set(@arr, ...)`
# calls write 16-byte sp_RbVal entries into 8-byte IntArray slots,
# corrupting adjacent memory and skewing `@arr.length`.
#
# An equivalent guard exists for ptr_array slots; this PR extends
# it to poly_array slots (constructor + general InstanceVariable-
# WriteNode paths) so the lowered storage matches the slot.

class Holder
  def initialize
    @arr = [nil] * 3
    @arr[0] = 42      # int
    @arr[1] = "two"   # str — heterogeneous → @arr widens to poly_array
  end
  attr_reader :arr

  def count
    @arr.length
  end
end

puts Holder.new.count   # 3
