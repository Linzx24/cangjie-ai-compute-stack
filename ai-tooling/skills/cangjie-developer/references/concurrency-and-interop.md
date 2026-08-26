# Concurrency and C interop

Read this only for concurrent code, native kernels, BLAS, accelerator runtimes, or other C libraries. These areas are platform-sensitive and require narrower verification than ordinary pure-Cangjie code.

## Concurrency

- `spawn` accepts a parameterless Lambda and starts a Cangjie thread.
- A successful compile does not prove the absence of races. Identify shared mutable state and the synchronization rule before parallelizing a loop.
- Prefer isolated work and immutable inputs. Protect shared writes with an appropriate synchronization primitive from the pinned SDK.
- Do not assume a Cangjie thread remains on one operating-system thread. This matters for native libraries that use thread-local state or thread affinity.
- Measure before parallelizing numerical kernels; scheduling and synchronization can cost more than a small operation saves.

## C FFI

- Declare C functions with `foreign func`; `@C` may be omitted on a foreign declaration.
- Call foreign functions inside the smallest practical `unsafe` block.
- The declared signature must exactly match the C ABI and supported Cangjie/C type mapping.
- Record ownership for every pointer: allocator, deallocator, lifetime, nullability, mutability, alignment, and whether C retains it after return.
- Configure native libraries in `cjpm.toml` under `[ffi.c]`, with target-specific configuration when paths or binaries differ by platform.
- Do not pass a guessed BLAS signature or keep a pointer past its documented lifetime. Add a tiny known-answer integration test before wiring it into Tensor operations.

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
