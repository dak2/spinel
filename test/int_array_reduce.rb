# Array#inject and Array#reduce share compile_reduce_block but have
# distinct dispatch entries. Cover both so a divergence at either
# entry surfaces. The block param `i` must also shadow an outer
# same-named local of a different C type without leaking back out.

i = "hi"
puts i

foo = [1, 2, 3, 4, 5]
sum_inject = foo.inject(0) { |acc, i| acc + i }
puts sum_inject   # 15

sum_reduce = foo.reduce(0) { |acc, i| acc + i }
puts sum_reduce   # 15
