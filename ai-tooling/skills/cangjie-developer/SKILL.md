---
name: cangjie-developer
description: Develop, debug, and verify Cangjie 1.1.3 projects with cjc and cjpm. Use for .cj code, cjpm packages, tests, language features, C interop, concurrency, numerical code, or Cangjie compiler errors. Do not use for unrelated languages or machine-learning explanations without Cangjie implementation work.
---

# Cangjie Developer

Use the pinned Cangjie compiler as the source of truth. Compile uncertain syntax instead of importing habits from another language.

Honor the caller's access and output contract before this workflow. If a response-only or structured-output task forbids filesystem or tool use, do not call tools or attempt placeholder commands: reason from the supplied files, return only the requested artifact, and do not claim compilation.

For an exact structured file response, copy every requested project-relative path character for character. Return `src/name.cj` when that is the declared path—never add a source-tree label such as `starter/`, never add an undeclared file, and never wrap the JSON object in prose or a code fence. Check the returned path set against the requested path set immediately before answering.

## Workflow

1. Read repository instructions, `cjpm.toml`, source, and tests before editing. Run `scripts/check-environment.ps1` only when the SDK state is unknown.
2. Read only the references needed for the task; prefer one or two topic references over a broad bundle:
   - Read [language-pitfalls.md](references/language-pitfalls.md) for bindings, numeric types, functions, Lambda, arrays, tuples, `Option`, pattern matching, exceptions, or compiler errors.
   - Read [abstraction-and-collections.md](references/abstraction-and-collections.md) for struct/class choice, interfaces, inheritance, generics, visibility, extensions, or collection types.
   - Read [project-and-test.md](references/project-and-test.md) for package layout, `cjpm`, unit tests, or platform checks.
   - Read [ai-compute-patterns.md](references/ai-compute-patterns.md) for tensors, layers, convolution, stable reductions, or quantized numerical kernels.
   - Read [ml-autodiff-training.md](references/ml-autodiff-training.md) for gradients, reverse-mode graphs, parameters, optimizers, or training loops.
   - Read [ml-data-state.md](references/ml-data-state.md) for samplers, masks, ragged batches, cursors, epochs, caches, or reset semantics.
   - Read [ml-checkpoint.md](references/ml-checkpoint.md) for deterministic serialization, file I/O, save/load, versioning, or corrupted input.
   - Read [concurrency-and-interop.md](references/concurrency-and-interop.md) only for `spawn`, synchronization, backends, C FFI, native libraries, BLAS, or unsafe code.
   - Read [ml-preflight.md](references/ml-preflight.md) before implementing and again before final review of a substantial multi-file numerical change.
   - Read [compiler-diagnostics.md](references/compiler-diagnostics.md) after a compiler failure or when code resembles another language.
3. Make the smallest coherent change; default to CPU-only and dependency-light. For a new small numerical core or state/I/O component, adapt the compile-tested project in `assets/` instead of recreating SDK patterns from memory.
4. When execution is allowed, run `scripts/Invoke-CangjieQualityGate.ps1 -ProjectPath <manifest-directory>` for preflight, build, and tests; add `-StrictNumerical` only for a substantial multi-file numerical change. Findings are review prompts; `cjc` and behavioral tests are authoritative. Fix the first useful diagnostic, rerun the narrow failure, then rerun the full gate. Report verification honestly.

## Non-negotiable rules

- Target Cangjie `1.1.3` unless the repository pins another version.
- During a repair task, preserve existing public names, signatures, and visibility unless the stated contract explicitly requires an API change.
- Match package declarations to the `cjpm` module and directory layout; do not invent imports or APIs without checking the pinned SDK.
- Use `var` for bindings that are reassigned. A struct method that changes fields must be declared `mut func`, and the struct instance must also be mutable. A class method does not use `mut`, even when it changes class fields.
- Keep braces around `if`, `for`, `while`, and `try` bodies; Cangjie does not accept Java-style `if (condition) statement`.
- Keep numeric types explicit. Convert counts with `Float64(count)` before floating-point division. Import `std.math.*` for `sqrt`, `exp`, `log`, or `pow`; use `log`, not `ln`.
- Reject `NaN`/`Inf` with `isNaN()`/`isInf()` wherever the public contract requires finite values, and validate exact endpoints before loops or delegated calls.
- Copy an `Array<T>` by allocating the destination and filling it by index; `Array<T>(source)` is not a copy constructor in the pinned SDK.
- A `String` index in the pinned SDK yields `UInt8`, and ordinary indices are `Int64`. Do not invent `Char`, `usize`, or Java-style `substring`; use exact `split` delimiters or compare ASCII bytes with values such as `UInt8(48)` and `UInt8(57)`.
- Keep `unsafe` local to the smallest C-interop operation. Never guess a foreign signature, ownership rule, or library path.
- Validate tensor shapes, overflow-prone size calculations, and indices before numerical loops. Prefer a flat row-major `Array<Float64>` for an initial Tensor implementation.
- Accumulate gradient contributions from shared graph paths. For stateful operations, compute and validate complete candidate values before one commit; rejected calls must preserve every public observable.
- In concurrent numerical code, let workers return private results and merge them after `Future.get()` in deterministic order instead of writing a captured output array.
- Test a small known answer, invalid boundaries, ownership isolation, and at least two relevant state transitions. Windows success is not Linux proof.
- Never hide compiler output or claim unverified code was tested.
