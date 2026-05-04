# Regression test: Hash#delete must compact the insertion-order array
# so that subsequent #keys / #values / each iteration skip the deleted
# entry. The Robin Hood backing array was being repaired correctly on
# delete but the parallel `order[]` array was not, so #keys returned the
# stale key and #values returned a zero / NULL slot for it.

# String keys
sh = {"a" => 1, "b" => 2, "c" => 3}
sh.delete("b")
puts sh.keys.inspect          # ["a", "c"]
puts sh.values.inspect        # [1, 3]
puts sh.length                # 2

# Symbol keys (the path that exposed the bug via PR #246)
yh = {a: 1, b: 2, c: 3}
yh.delete(:b)
puts yh.keys.inspect          # [:a, :c]
puts yh.values.inspect        # [1, 3]

# Delete first / last entries (boundary cases for the shift loop)
fh = {a: 1, b: 2, c: 3}
fh.delete(:a)
puts fh.keys.inspect          # [:b, :c]

lh = {a: 1, b: 2, c: 3}
lh.delete(:c)
puts lh.keys.inspect          # [:a, :b]
