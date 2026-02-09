# AGENTS.md - Jay (BlueJay Engine)

A game/rendering engine written in the **Jai** programming language. The engine is
composed of modular subsystems (ECS, math, rendering, logging) organized as git
submodules under `engine/`. Jai has no standardized linting, formatting, or test
framework tooling -- conventions are enforced manually.

## Build Commands

The Jai compiler must be installed (expected at `~/jai/`). All commands run from
the project root.

```bash
# Standard debug build (X64 backend, bounds checking ON)
jai build.jai

# Optimized build (LLVM backend, VERY_OPTIMIZED)
jai build.jai - opt

# Release build (LLVM backend, OPTIMIZED_VERY_SMALL)
jai build.jai - release
```

The build metaprogram (`build.jai`) compiles `main.jai` as the entry point.
Output goes to `bin/` (executable name matches the project folder: `bin/Jay`).

The `engine/` directory is added to the import path automatically by `build.jai`,
so engine modules are available via `#import "Jay_ECS"` etc.

## Testing

There is no unified test runner. Tests are standalone Jai programs or compile-time
`#run` blocks. Run individual tests by compiling them directly with `jai`.

```bash
# Main build script:
jai build.jai

# Build with optimizations:
jai build.jai - release
```

Tests verify correctness via `assert` (fatal on failure) and `log_error` messages.
Memory leak detection is done with `report_memory_leaks(.{})` at end of test mains.
Performance tests log elapsed time in microseconds or milliseconds.

When running single-file tests outside the build system, you may need to pass the
engine import path: `jai <file> -import_dir engine`.

## Project Architecture

```
Jay/
  build.jai              # Build metaprogram (configures compiler)
  main.jai               # Application entry point
  engine/                # Engine modules (git submodules)
    Jay_Core/            # Engine lifecycle, timer, threading, Mixer
    Jay_ECS/             # Archetype-based Entity Component System
    Jay_Math/            # Vectors, matrices, quaternions, SIMD, cephes
    Jay_Logger/          # Colored console logging with timestamps
    Jay_Render/          # Vulkan renderer with SDL3 windowing
    Jay_Utils/           # Utility functions (type reinterpretation, note parsing)
    Slang/               # Jai bindings for Slang shader compiler
    jai-sdl3/            # Jai bindings for SDL3
    jai-vma/             # Jai bindings for Vulkan Memory Allocator
    Jay_Vulkan/          # Jai bindings for Vulkan API
  assets/shaders/        # .slang shader source files
  bin/                   # Build output (executable + shared libs)
```

Each engine module has a `module.jai` entry point that `#load`s its sub-files.
Third-party bindings are also submodules but are not prefixed with `Jay_`.

## Code Style Guidelines

### Imports

- `#import` at top of file, one per line, **not** alphabetically sorted.
- Order: standard library imports first, then engine/project modules.
- Parametric imports for module configuration: `#import "Basic"()(MEMORY_DEBUGGER = true);`
- `#load` for intra-module file inclusion, with short inline comments:
  ```jai
  #load "world.jai";       // Everything lives here
  #load "archetype.jai";   // Everything stores here
  ```
- Re-export sub-modules with `using`: `using Math :: #import "Jay_Math";`
- Platform-conditional imports via `#if OS == .LINUX { #load "linux.jai"; }`

### Naming Conventions

| Element              | Convention                          | Example                          |
|----------------------|-------------------------------------|----------------------------------|
| Structs/Types        | `Pascal_Snake`                      | `Entity`, `Entity_State`, `Swapchain_Data` |
| Functions            | `snake_case`                        | `make_archetype`, `instance_get` |
| Local variables      | `snake_case`                        | `e_index`, `target_signature`    |
| Struct fields        | `snake_case`                        | `max_count`, `to_destroy`        |
| Constants            | `SCREAMING_SNAKE_CASE`              | `ENTITY_NULL`, `MAX_SWAPCHAIN_IMAGES` |
| Enum members         | `SCREAMING_SNAKE_CASE`              | `Q_ITER`, `INC_QUERIES`         |
| Files                | `snake_case.jai`                    | `world.jai`, `shader_utils.jai` |
| Engine modules       | `Jay_` prefix + `PascalCase`        | `Jay_ECS`, `Jay_Core`           |
| Type aliases         | `Pascal_Snake`                        | `Delta_Time :: float64;`        |

### Types

- Define types inline in the file where they belong (no separate types files).
- One primary concept per file: `world.jai` defines `World`, `entity.jai` defines `Entity`.
- Use polymorphic (generic) structs with compile-time parameters:
  `Archetype :: struct (reg: [$SIZE]Type) { ... }`
- Use `#modify` blocks for compile-time type validation on structs and functions.
- Type aliases via `::` constant declarations: `Delta_Time :: float64;`

### Error Handling

- `assert` for internal invariants and preconditions (include descriptive format strings):
  `assert(arch && index >= 0, "Invalid arch (%) or index (%)", arch.signature, index);`
- `log_error` for user-facing / recoverable errors.
- Boolean return values for success/failure on operations that can fail.
- `exit(1)` only for fatal build/initialization errors.
- Vulkan-style: check result codes against `.SUCCESS`.
- No exceptions -- Jai does not have try/catch.

### Visibility and Module Structure

- Public API at the **top** of each file.
- `#scope_file` near the bottom to mark everything after it as file-private.
- `#scope_module` to mark everything after it as module-private.
- Module entry point is always `module.jai`, which `#load`s all sub-files.
- Use `#module_parameters` for module-level compile-time configuration:
  `#module_parameters(DEBUG := false);`

### Functions

- Use Jai constant declaration syntax: `name :: (params) -> (return_types) { ... }`
- Mark hot-path functions with `inline` liberally (ECS entity ops, queries, signatures).
- Function overloading by parameter types is common (same name, different signatures).
- Heavy use of compile-time metaprogramming: `#insert`, `#run`, `#modify`.
- Lambda-style inline functions in struct literals for dispatch tables.

### Dependency Injection / Context

- Use `#add_context` to extend Jai's thread-local context for implicit parameter passing:
  ```jai
  #add_context world_ptr: *void;
  #add_context ent_procs := _default_ent_procs;
  ```
- Default context values should provide error messages when used outside proper scope.

### Memory Management

- Use `defer` for cleanup of allocated resources.
- Use `report_memory_leaks(.{})` at end of test/debug mains.
- Use temporary allocator via `,, temp` parameter for short-lived allocations.

### Comments

- `//` inline comments are the dominant style. Keep them short and contextual.
- Multi-line documentation uses repeated `//` lines (no doc-comment system).
- Conversational/informal tone is acceptable in documentation comments.
- Mark unfinished work with `// TODO:` comments.
- Commented-out code is acceptable as debug toggles but should be minimal.

### Logging

- Use the custom `jay_logger` by setting `context.logger = jay_logger;` in main.
- Use standard `log()` for info and `log_error()` for errors -- they route through
  the context logger which adds ANSI colors, timestamps, and thread indices.
