# Issue #169: p / inspect on nested arrays whose element type is one
# of the four built-in T_array shapes (int/str/float/sym).

p [[1, 2], [3, 4]]
p [[1, 2, 3], [4, 5, 6]]
p [[10]]
p [[1, 2], [3, 4]].transpose

p [["a", "b"], ["c", "d"]]
p [["hello", "world"]]

p [[1.5, 2.5], [3.5, 4.5]]
p [[0.1]]

p [[:a, :b], [:c, :d]]
p [[:foo]]
