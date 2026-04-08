# Spinel -- Ruby AOT Compiler

Spinel compiles Ruby source code into standalone native executables.
It performs whole-program type inference and generates optimized C code,
achieving significant speedups over CRuby.

Spinel is **self-hosting**: the compiler backend is written in Ruby and
compiles itself into a native binary.

## How It Works

```
Ruby (.rb)
    |
    v
spinel_parse           Parse with Prism (libprism), serialize AST
    |                  (C binary, or CRuby + Prism gem as fallback)
    v
AST text file
    |
    v
spinel_codegen         Type inference + C code generation
    |                  (self-hosted native binary)
    v
C source (.c)
    |
    v
cc -O2 -Ilib -lm      Standard C compiler + runtime header
    |
    v
Native binary           Standalone, no runtime dependencies
```

## Quick Start

```bash
# Build everything:
make

# Write a Ruby program:
cat > hello.rb <<'RUBY'
def fib(n)
  if n < 2
    n
  else
    fib(n - 1) + fib(n - 2)
  end
end

puts fib(34)
RUBY

# Compile and run:
./spinel hello.rb
./hello               # prints 5702887 (instantly)
```

### Options

```bash
./spinel app.rb              # compiles to ./app
./spinel app.rb -o myapp     # compiles to ./myapp
./spinel app.rb -c           # generates app.c only
./spinel app.rb -S           # prints C to stdout
```

## Self-Hosting

Spinel compiles its own backend. The bootstrap chain:

```
CRuby + spinel_parse.rb → AST
CRuby + spinel_codegen.rb → gen1.c → bin1
bin1 + AST → gen2.c → bin2
bin2 + AST → gen3.c
gen2.c == gen3.c   (bootstrap loop closed)
```

## Benchmarks

52/53 benchmarks pass. 65 tests pass.

### Computation

| Benchmark | Spinel | CRuby | Speedup |
|-----------|--------|-------|---------|
| life (Game of Life) | 2 ms | 1,487 ms | **743x** |
| ackermann | 6 ms | 397 ms | **66x** |
| mandelbrot | 24 ms | 1,179 ms | **49x** |
| matmul | 8 ms | 319 ms | **39x** |
| nqueens | 770 ms | 25,600 ms | **33x** |
| tarai | 16 ms | 433 ms | **27x** |
| tak | 22 ms | 506 ms | **23x** |
| sudoku | 7 ms | 148 ms | **21x** |
| sieve | 20 ms | 410 ms | **20x** |
| partial_sums | 82 ms | 1,282 ms | **15x** |

### Data Structures & GC

| Benchmark | Spinel | CRuby | Speedup |
|-----------|--------|-------|---------|
| rbtree (red-black tree) | 18 ms | 579 ms | **32x** |
| splay tree | 10 ms | 210 ms | **21x** |
| so_lists | 29 ms | 520 ms | **17x** |
| gcbench | 486 ms | 4,425 ms | **9x** |
| linked_list | 63 ms | 484 ms | **7.7x** |
| binary_trees | 5 ms | 80 ms | **16x** |

### Real-World Programs

| Benchmark | Spinel | CRuby | Speedup |
|-----------|--------|-------|---------|
| fasta (DNA seq gen) | 1,260 ms | 7,700 ms | **6.1x** |
| io_wordcount | 29 ms | 151 ms | **5.2x** |
| json_parse | 104 ms | 453 ms | **4.4x** |
| template engine | 227 ms | 983 ms | **4.3x** |
| csv_process | 273 ms | 952 ms | **3.5x** |
| pidigits (bigint) | 6,300 ms | 11,600 ms | **1.8x** |

## Supported Ruby Features

**Core**: Classes, inheritance, `super`, `include` (mixin), `attr_accessor`,
`Struct.new`, `alias`, module constants, open classes for built-in types.

**Control Flow**: `if`/`elsif`/`else`, `unless`, `case`/`when`,
`case`/`in` (pattern matching), `while`, `until`, `loop`, `for..in`
(range and array), `break`, `next`, `return`, `catch`/`throw`,
`&.` (safe navigation).

**Blocks**: `yield`, `block_given?`, `&block`, `proc {}`, `Proc.new`,
lambda `-> x { }`, `method(:name)`. Block methods: `each`,
`each_with_index`, `map`, `select`, `reject`, `reduce`, `sort_by`,
`any?`, `all?`, `none?`, `times`, `upto`, `downto`.

**Exceptions**: `begin`/`rescue`/`ensure`/`retry`, `raise`,
custom exception classes.

**Types**: Integer, Float, String (immutable + mutable), Array, Hash,
Range, Time, StringIO, File, Regexp, Bigint (auto-promoted), Fiber.
Polymorphic values via tagged unions. Nullable object types (`T?`)
for self-referential data structures (linked lists, trees).

**Global Variables**: `$name` compiled to static C variables with
type-mismatch detection at compile time.

**Strings**: `<<` automatically promotes to mutable strings (`sp_String`)
for O(n) in-place append. `+`, interpolation, `tr`, `ljust`/`rjust`/`center`,
and all standard methods work on both. Character comparisons like
`s[i] == "c"` are optimized to direct char array access (zero allocation).

**Regexp**: Built-in NFA regexp engine (no external dependency).
`=~`, `$1`-`$9`, `match?`, `gsub(/re/, str)`, `sub(/re/, str)`,
`scan(/re/)`, `split(/re/)`.

**Bigint**: Arbitrary precision integers via mruby-bigint. Auto-promoted
from loop multiplication patterns (e.g. `q = q * k`). Linked as static
library -- only included when used.

**Fiber**: Cooperative concurrency via `ucontext_t`. `Fiber.new`,
`Fiber#resume`, `Fiber.yield` with value passing. Captures free
variables via heap-promoted cells.

**Memory**: Mark-and-sweep GC with size-segregated free lists, non-recursive
marking, and sticky mark bits. Small classes (<=4 fields, no inheritance,
no mutation through parameters) are automatically stack-allocated as
**value types**. Programs using only value types emit no GC runtime at all.

**I/O**: `puts`, `print`, `printf`, `p`, `gets`, `ARGV`, `ENV[]`,
`File.read/write/open` (with blocks), `system()`, backtick.

## Architecture

```
spinel                One-command wrapper script (POSIX shell)
spinel_parse.c        C frontend: libprism → text AST (1,061 lines)
spinel_codegen.rb     Compiler backend: AST → C code (17,162 lines)
lib/sp_runtime.h      Runtime library header (455 lines)
lib/sp_bigint.c       Arbitrary precision integers (5,406 lines)
lib/regexp/           Built-in regexp engine (1,759 lines)
test/                 65 feature tests
benchmark/            53 benchmarks
Makefile              Build automation
```

The compiler backend (`spinel_codegen.rb`) is written in a Ruby subset
that Spinel itself can compile: classes, `def`, `attr_accessor`,
`if`/`case`/`while`, `each`/`map`/`select`, `yield`, `begin`/`rescue`,
String/Array/Hash operations, File I/O.

No metaprogramming, no `eval`, no `require` in the backend.

The runtime (`lib/sp_runtime.h`) contains GC, array/hash/string
implementations, and all runtime support as a single header file.
Generated C includes this header, and the linker pulls only the
needed parts from `libspinel_rt.a` (bigint + regexp engine).

The parser has two implementations:
- **spinel_parse.c** links libprism directly (no CRuby needed)
- **spinel_parse.rb** uses the Prism gem (CRuby fallback)

Both produce identical AST output. The `spinel` wrapper prefers the
C binary if available. `require_relative` is resolved at parse time
by inlining the referenced file.

## Building

```bash
make              # build parser + regexp library + bootstrap compiler
make test         # run 65 feature tests (requires bootstrap)
make bench        # run 53 benchmarks (requires bootstrap)
make bootstrap    # rebuild compiler from source
sudo make install # install to /usr/local (spinel in PATH)
make clean        # remove build artifacts
```

Override install prefix: `make install PREFIX=$HOME/.local`

Requires [Prism](https://github.com/ruby/prism) gem installed (for
libprism source). Override with `PRISM_DIR=/path/to/prism`.

CRuby is needed only for the initial bootstrap. After `make`, the
entire pipeline runs without Ruby.

## Limitations

- **No eval**: `eval`, `instance_eval`, `class_eval`
- **No metaprogramming**: `send`, `method_missing`, `define_method` (dynamic)
- **No threads**: `Thread`, `Mutex` (Fiber is supported)
- **No encoding**: assumes UTF-8/ASCII
- **No general lambda calculus**: deeply nested `-> x { }` with `[]` calls

## Dependencies

- **Build time**: [libprism](https://github.com/ruby/prism) (C library),
  CRuby (bootstrap only)
- **Run time**: None. Generated binaries need only libc + libm.
- **Regexp**: Built-in engine, no external library needed.
- **Bigint**: Built-in (from mruby-bigint), linked only when used.

## History

Spinel was originally implemented in C (18K lines, branch `c-version`),
then rewritten in Ruby (branch `ruby-v1`), and finally rewritten in a
self-hosting Ruby subset (current `master`).

## License

MIT License. See [LICENSE](LICENSE).
