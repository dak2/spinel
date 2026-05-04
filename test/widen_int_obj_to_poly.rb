# When an ivar's first observed write is a definite int / nil
# literal and a later write assigns an obj-typed value, the slot
# was overwritten with the obj type — silently casting the prior
# int payload to a struct pointer. Subsequent dispatch through
# the slot then read garbage or computed pointer arithmetic.
#
# Widening to poly so the slot carries either case at runtime
# preserves the program's actual semantics: the dispatch path
# decides per cls_id at the call site.

class Box
  def initialize(n)
    @n = n
    @arr = []
    @arr << n
  end
  attr_reader :n
end

class Holder
  def initialize
    @poly = 10              # definite int first
    @poly = Box.new(5)      # …then obj — slot widens to poly
  end
  attr_reader :poly
end

# poly recv → Box#n via cls_id == Box dispatch
puts Holder.new.poly.n      # 5
