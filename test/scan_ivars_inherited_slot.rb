# When a child class first writes to an ivar that already lives on
# a parent, scan_ivars used to register the ivar on the child too.
# update_ivar_type then recursed up to the parent and widened
# (e.g. `int` → `poly` for heterogeneous writes), but the child's
# own-table entry kept the new write's narrower type. Two tables
# disagreed about the slot — and downstream type lookups picked
# the wrong one depending on path, so codegen for the same field
# disagreed across class methods.
#
# Now scan_ivars detects that the slot is already in an ancestor's
# table and routes the write through update_ivar_type without
# adding a duplicate entry to the child. The parent's table stays
# the single source of truth.

class Parent
  def initialize
    @v = 0
    @v = "s"     # parent widens @v to poly
  end
end

class Child < Parent
  def initialize
    super
    @v = 42      # child writes through inherited slot
  end
  def read
    @v
  end
end

puts Child.new.read     # 42
