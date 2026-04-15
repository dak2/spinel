# Symbol-keyed hash: keys are sp_sym, distinct from string keys
h = {a: 1, b: 2, c: 3}
puts h[:a]      # 1
puts h[:b]      # 2
puts h.length   # 3
puts h.has_key?(:a)  # true
puts h.has_key?(:z)  # false
puts h.empty?       # false
h[:d] = 4
puts h[:d]      # 4
puts h.length   # 4
