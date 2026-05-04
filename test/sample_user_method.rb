# `infer_method_name_type` had a name-based shortcut for `sample`
# that returned the Array#sample default of int regardless of recv.
# A user-defined `sample` on an obj receiver inferred as int even
# though the method returns a non-int — and downstream consumers
# (puts, comparisons, etc.) used the wrong shape.

class Box
  def initialize(label)
    @label = label
  end

  attr_reader :label

  def sample
    @label
  end
end

b = Box.new("ok")
puts b.sample    # ok
