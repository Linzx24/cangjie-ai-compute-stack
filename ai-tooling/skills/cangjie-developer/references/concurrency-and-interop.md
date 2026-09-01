# Concurrency and C interop

Read this only for concurrent code, native kernels, BLAS, accelerator runtimes, or other C libraries. These areas are platform-sensitive and require narrower verification than ordinary pure-Cangjie code.

## Concurrency

- `spawn` accepts a parameterless Lambda and starts a Cangjie thread.
- `spawn` returns a `Future<T>`; obtain the completed value with `future.get()`. Do not import `std.thread`: it is not a module in the pinned SDK. `Future` and `spawn` need no such import. If futures are stored in an `ArrayList`, import `std.collection.*` for the collection itself.
- A successful compile does not prove the absence of races. Identify shared mutable state and the synchronization rule before parallelizing a loop.
- Prefer isolated work and immutable inputs. Protect shared writes with an appropriate synchronization primitive from the pinned SDK.
- Do not assume a Cangjie thread remains on one operating-system thread. This matters for native libraries that use thread-local state or thread affinity.
- Measure before parallelizing numerical kernels; scheduling and synchronization can cost more than a small operation saves.
- Give each worker an immutable input slice and private accumulator/output. Join futures in a deterministic range order and reduce partial results in that same order when floating-point reproducibility matters; never let worker completion order define the answer.
- A worker exception is part of the public failure contract: call `get()` on every submitted future, propagate the first useful failure, and do not publish a partially filled output. Test repeated calls and a deliberately failing worker where the API permits it.

## C FFI

- Declare C functions with `foreign func`; `@C` may be omitted on a foreign declaration.
- Call foreign functions inside the smallest practical `unsafe` block.
- The declared signature must exactly match the C ABI and supported Cangjie/C type mapping.
- Record ownership for every pointer: allocator, deallocator, lifetime, nullability, mutability, alignment, and whether C retains it after return.
- Configure native libraries in `cjpm.toml` under `[ffi.c]`, with target-specific configuration when paths or binaries differ by platform.
- Do not pass a guessed BLAS signature or keep a pointer past its documented lifetime. Add a tiny known-answer integration test before wiring it into Tensor operations.
- Treat a device/backend capability report as a promise: return `true` only when the operation is actually available and callable on the current target. Unknown, unavailable GPU/NPU, or unsupported operations must either use a tested CPU fallback or fail with a documented error; they must not claim accelerator execution. Keep device ownership and pointer lifetimes explicit across every boundary.

## Verification ladder for a native dependency

1. Compile and test the pure-Cangjie fallback.
2. Link one native function with a hand-checkable input and output.
3. Test invalid dimensions, empty inputs, and ownership cleanup.
4. Run on every claimed target; Windows success is not Linux proof.
5. Compare numerical tolerance and benchmark against the fallback before selecting the native path.

## Official references

- [Creating Cangjie threads](https://cj-docs.gitcode.com/zh/1.1.3/dev-guide/source_zh_cn/concurrency/create_thread.html)
- [Cangjie-C interoperability](https://cj-docs.gitcode.com/zh/1.1.3/dev-guide/source_zh_cn/FFI/cangjie-c.html)
- [cjpm manual, including `ffi.c` and target configuration](https://cj-docs.gitcode.com/zh/1.1.3/tools/source_zh_cn/cmd-tools/cjpm_manual.html)
