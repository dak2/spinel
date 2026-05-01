# Array#take_while and Array#drop_while for int_array (the common case).
# take_while collects elements from the front while the block stays
# truthy; drop_while skips them and returns the rest.

# take_while
puts [1, 2, 3, 1].take_while { |x| x < 3 }.inspect
puts [1, 2, 3].take_while { |x| x < 10 }.inspect
puts [5, 6, 7].take_while { |x| x < 0 }.inspect
puts [].take_while { |x| x > 0 }.inspect

# drop_while
puts [1, 2, 3, 1].drop_while { |x| x < 3 }.inspect
puts [1, 2, 3].drop_while { |x| x < 10 }.inspect
puts [5, 6, 7].drop_while { |x| x < 0 }.inspect
puts [].drop_while { |x| x > 0 }.inspect

# take_while + drop_while round-trip preserves total count
arr = [1, 2, 3, 4, 5, 1, 2]
puts(arr.take_while { |x| x < 4 }.length + arr.drop_while { |x| x < 4 }.length)

# Multi-stmt block — preceding statements must execute (regression for the
# "only last expr is compiled" bug).
counter = 0
[1, 2, 3, 4].take_while { |x| counter = counter + 1; x < 3 }
puts counter

# sym_array path (regression for the bp-hardcoded-int bug).
puts [:a, :b, :c, :d].take_while { |s| s != :c }.inspect
puts [:a, :b, :c, :d].drop_while { |s| s != :c }.inspect
