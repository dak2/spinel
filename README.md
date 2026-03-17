# Spinel — AOT Compiler for Ruby

Spinel compiles Ruby source code to standalone C executables via
[Prism](https://github.com/ruby/prism) parsing and whole-program type inference.
Classes become C structs, methods become direct function calls, and numeric
operations compile to native C arithmetic with zero dynamic dispatch overhead.
Generated binaries have no runtime dependencies — no mruby, no GC, just libc and libm.

## Quick Start

```bash
# 1. Fetch and build the Prism parser library
make deps

# 2. Build the spinel compiler
make

# 3. Compile a Ruby program to C, then to a native binary
./spinel --source=app.rb --output=app.c
cc -O2 app.c -lm -o app
```

## Benchmarks

| Benchmark | CRuby 3.2 | mruby | **Spinel AOT** | Speedup |
|-----------|-----------|-------|----------------|---------|
| mandelbrot (600x600 PBM) | 1.14s | 3.18s | **0.02s** | **57x** |
| ao_render (64x64 AO raytracer) | 3.55s | 13.69s | **0.06s** | **59x** |

Binary sizes: mandelbrot 16KB, ao_render 21KB (stripped).

```bash
make test   # compile mandelbrot, run, verify output matches CRuby
```

## How It Works

```
Ruby Source (.rb)
    |
    v
Prism (libprism)             -- parse to AST
    |
    v
Pass 1: Class Analysis       -- find classes, methods, instance variables
    |
    v
Pass 2: Type Inference        -- infer types for all variables, ivars, params
    |                            (Integer, Float, Boolean, Object types)
    v
Pass 3: Struct/Method Emit    -- classes -> C structs
    |                            methods -> C functions (direct calls)
    |                            getters/setters -> inline field access
    v
Pass 4: Main Codegen          -- top-level code -> main()
    |                            while/for/times -> C loops
    |                            arithmetic -> C operators
    |                            puts/print/printf -> stdio
    v
Standalone C file
    |
    v
cc -O2 -lm -> native binary   -- no mruby, no GC, just libc
```

For `bm_ao_render.rb`, the compiler:
- Converts 6 Ruby classes (Vec, Sphere, Plane, Ray, Isect, Scene) into C structs
- Vec (3 floats) is passed/returned by value — no heap allocation
- All method calls are devirtualized to direct C function calls
- `Integer#times` blocks become C for loops
- `Math.sqrt/cos/sin` map directly to C math functions
- The Rand module's xorshift PRNG compiles to inline integer arithmetic

## Supported Language Features

| Feature | Example |
|---------|---------|
| Classes with instance variables | `class Vec; def initialize(x,y,z); @x=x; end; end` |
| Method definitions | `def vadd(b); Vec.new(@x+b.x, ...); end` |
| Getters/setters (inlined) | `def x; @x; end` / `def x=(v); @x=v; end` |
| Object construction | `Vec.new(1.0, 2.0, 3.0)` |
| Method calls on typed objects | `ray.org.vsub(@center)` |
| Modules with state | `module Rand; @x = 123; def self.rand; ...; end; end` |
| Local variables, constants | `size = 600`, `ITER = 49` |
| `while` loops | `while x <= count_size` |
| `Integer#times` with block | `n.times do \|i\| ... end` |
| `if` / `elsif` / `else` | conditional branching |
| Ternary operator | `escape ? 0 : 1` |
| `and` / `or` | `t > 0.0 and t < isect.t` |
| Arithmetic, comparison, bitwise | `+`, `-`, `*`, `/`, `%`, `<`, `>`, `==`, `<<`, `\|`, `^` |
| Unary minus | `-b`, `-(expr)` |
| `Math.sqrt`, `Math.cos`, `Math.sin` | C math functions |
| String interpolation | `"P4\n#{size} #{size}"` → printf |
| `puts`, `print`, `printf` | stdio calls |
| `Integer#chr` | `print byte_acc.chr` → putchar |
| `break`, `return` | loop/method exit |
| Parallel assignment | `zr, zi = tr, ti` |
| Array indexing | `basis[0].x`, `@spheres[1].intersect(...)` |

## Project Structure

```
spinel/
├── src/
│   ├── main.c        # CLI, file reading, Prism parsing
│   ├── codegen.h     # Type system, class/method/module info structs
│   └── codegen.c     # Multi-pass code generator (~2000 lines)
├── prototype/
│   └── tools/        # Step 0 prototype (RBS extraction, LumiTrace, etc.)
├── bm_so_mandelbrot.rb   # Benchmark: Mandelbrot set renderer
├── bm_ao_render.rb       # Benchmark: Ambient occlusion raytracer
├── Makefile
├── PLAN.md               # Implementation roadmap
└── ruby_aot_compiler_design.md  # Detailed design document
```

## Dependencies

- **Build time**: [Prism](https://github.com/ruby/prism) (fetched automatically by `make deps`)
- **Run time**: None. Generated binaries are standalone (libc + libm only).

## License

Spinel is released under the [MIT License](LICENSE).

### Note on License

mruby has chosen a MIT License due to its permissive license allowing
developers to target various environments such as embedded systems.
However, the license requires the display of the copyright notice and license
information in manuals for instance. Doing so for big projects can be
complicated or troublesome. This is why mruby has decided to display "mruby
developers" as the copyright name to make it simple conventionally.
In the future, mruby might ask you to distribute your new code
(that you will commit,) under the MIT License as a member of
"mruby developers" but contributors will keep their copyright.
(We did not intend for contributors to transfer or waive their copyrights,
actual copyright holder name (contributors) will be listed in the [AUTHORS](AUTHORS)
file.)

Please ask us if you want to distribute your code under another license.
