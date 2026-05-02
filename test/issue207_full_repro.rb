# Issue #207: full Sam Ruby repro — Rails-style ActiveRecord
# Parameters wrapper with symbolize_keys recursion plus a typed
# Params factory using fetch.
#
# This combines several fixes that had to land together:
#
# - Implicit `new` inside `def self.<m>` resolves to the enclosing
#   class's constructor (#207 partial fix).
# - cls method body return inference picks up locals (#207 partial
#   fix).
# - attr_writer call inside cls method body widens the ivar slot.
# - Class-constant call sites (T.from_raw(p)) widen the cls method's
#   parameter types.
# - Static is_a? / kind_of? on a known-concrete-type receiver
#   eliminates the unreachable arm so the dead recursion call
#   doesn't land in C and trip the type checker.

class Parameters
  def initialize(hash = {})
    @hash = symbolize_keys(hash)
  end

  def symbolize_keys(input)
    out = {}
    input.each do |k, v|
      sym = k.is_a?(Symbol) ? k : k.to_s.to_sym
      out[sym] = v.is_a?(Hash) ? symbolize_keys(v) : v
    end
    out
  end

  def fetch(key, default = nil)
    sym = key.to_sym
    return @hash[sym] if @hash.key?(sym)
    default
  end
end

class ArticleParams
  def title; @title; end
  def title=(value); @title = value; end

  def self.from_raw(params)
    instance = new
    instance.title = params.fetch(:title, "")
    instance
  end
end

p = Parameters.new({title: "hello"})
ap = ArticleParams.from_raw(p)
puts ap.title
