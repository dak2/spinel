# Range#map (and the parenthesised form `(a..b).map { ... }`,
# which is what Ruby parsers usually produce). The compile path
# in spinel used to fall through to the default `"0"` return for
# Range receivers, so `tt = (0..3).map { |i| i * 10 }` silently
# became `tt = 0` and any subsequent `.each` / `[i]` was a bit
# shift, not an array op.

# Inclusive range, simple body
puts (0..3).map { |i| i * 10 }.length      # 4
puts (0..3).map { |i| i * 10 }[2]          # 20

# Exclusive range
puts (0...3).map { |i| i }.length          # 3
puts (0...3).map { |i| i }[2]              # 2

# String result
puts ((1..3).map { |i| "x#{i}" }.join(","))   # x1,x2,x3

# Float result
puts ((0...3).map { |i| i * 0.5 }.length)     # 3
