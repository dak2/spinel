# `Range#map` / `int_array.map` whose block returns an array
# (1D, 2D, 3D nested) used to silently degrade — the codegen
# returned `0` for non-int/string/float block returns at the
# Range#map path, and `int_array.map` boxed inner ptr_array
# results via `sp_box_ptr_array(val)` which erased the
# elem-type info (cls_id PTR_ARRAY only) so deeper indexing
# fell through every dispatch arm to `sp_box_nil()`.
#
# Fixes:
#
# - Range#map block returning a typed array now stores in
#   `sp_PtrArray` (matching the inferred `<bret>_ptr_array`
#   type). Deeper nesting (block returns ptr_array /
#   poly_array) stores in `sp_PolyArray` with `box_value_to_poly`
#   boxing — preserves cls_id chain for `arr[i][j][k]...`.
#
# - `int_array.map`'s deep-array branch (block returns
#   `<X>_ptr_array`) converts the inner sp_PtrArray to
#   sp_PolyArray inline via a per-element `sp_box_<elem>` re-tag,
#   so the outer PolyArray's elements carry the right cls_id at
#   the next dispatch level.
#
# Together this lets nested-map-of-array-block constructs
# (e.g. optcarrot's `TILE_LUT = [...].map { (0..7).map {
# (0...0x10000).map { ... } }.transpose }`) compile and read
# at every depth.

# Range#map -> int_array_ptr_array (2D)
class M2
  def initialize
    @t = (0..2).map { |i| (0..3).map { |j| i * 10 + j } }
  end
  def read(i, j); @t[i][j]; end
end
m2 = M2.new
puts m2.read(0, 0)   # 0
puts m2.read(1, 2)   # 12
puts m2.read(2, 3)   # 23

# int_array.map { Range#map { ... } } -> 3D via PolyArray
class M3
  def initialize
    @t = [10, 20].map do |a|
      (0..2).map { |b| [a + b, a + b + 100] }
    end
  end
  def read(i, j, k); @t[i][j][k]; end
end
m3 = M3.new
puts m3.read(0, 0, 0)   # 10
puts m3.read(0, 1, 1)   # 111
puts m3.read(1, 2, 0)   # 22
puts m3.read(1, 2, 1)   # 122
