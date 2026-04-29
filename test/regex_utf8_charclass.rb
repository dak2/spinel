# Issue #61 stage 2: the regex engine's character class implementation
# kept only an ASCII bitmap; non-ASCII codepoints were silently dropped
# at compile time (`if (ch < 128) class_set_bit`). With this stage the
# class also stores `(lo, hi)` codepoint ranges and the match site
# decodes UTF-8 before consulting the class.

# positive: codepoint range hits
puts(("₁" =~ /[₀-₉]/) ? "ok1" : "fail1")
puts(("α" =~ /[α-ω]/) ? "ok2" : "fail2")

# explicit char list (the issue's exact form)
puts(("abc₁def" =~ /[₀₁₂₃₄₅₆₇₈₉]+/) ? "ok3" : "fail3")

# negated with non-ASCII codepoint range
puts(("a"  =~ /[^₀-₉]/) ? "ok4" : "fail4")
puts(("₁" =~ /[^₀-₉]/) ? "fail5" : "ok5")

# mixed ASCII + non-ASCII in one class
puts(("z"  =~ /[a-z₀-₉]/) ? "ok6" : "fail6")
puts(("₅" =~ /[a-z₀-₉]/) ? "ok7" : "fail7")

# non-matching
puts(("₁" =~ /[α-ω]/) ? "fail8" : "ok8")
puts(("a"  =~ /[α-ω]/) ? "fail9" : "ok9")

# non-ASCII char class with quantifier
m = "abc₁₂₃def" =~ /[₀-₉]+/
puts(m ? "ok10" : "fail10")
