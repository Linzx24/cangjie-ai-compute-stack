---
name: cangjie-developer
description: Develop, debug, and verify Cangjie 1.1.3 projects with cjc and cjpm. Use for .cj code, cjpm packages, tests, language features, C interop, concurrency, numerical code, or Cangjie compiler errors. Do not use for unrelated languages or machine-learning explanations without Cangjie implementation work.
---

# Cangjie Developer

Use the real Cangjie 1.1.3 compiler as the source of truth. Do not rely on remembered syntax when a small compile or test can settle the question.

## Workflow

1. Read repository instructions and locate `cjpm.toml`, the source package, and tests before editing.
2. Run `scripts/check-environment.ps1` when the SDK or project state is unknown.
3. Read only the references needed for the task:
   - Read [language-pitfalls.md](references/language-pitfalls.md) for bindings, numeric types, functions, Lambda, arrays, tuples, `Option`, pattern matching, exceptions, or compiler errors.
   - Read [abstraction-and-collections.md](references/abstraction-and-collections.md) for struct/class choice, interfaces, inheritance, generics, visibility, extensions, or collection types.
   - Read [project-and-test.md](references/project-and-test.md) for package layout, `cjpm`, unit tests, or platform checks.
   - Read [concurrency-and-interop.md](references/concurrency-and-interop.md) for `spawn`, synchronization, C FFI, native libraries, BLAS, or unsafe code.
   - Read [ai-compute-patterns.md](references/ai-compute-patterns.md) for Tensor, numerical operations, or machine-learning primitives.
4. Make the smallest coherent change. Keep the first implementation CPU-only and dependency-light unless the task requires otherwise.
5. From the directory containing `cjpm.toml`, run `cjpm build` and then `cjpm test --no-color`.
6. On failure, preserve the exact first useful diagnostic, fix its root cause, and rerun. Do not change several unrelated things based on guesses.
7. Report success only with the command and result that verified it. State clearly when verification was impossible.

## Non-negotiable rules

- Target Cangjie `1.1.3` unless the repository pins another version.
- Match package declarations to the `cjpm` module and directory layout; do not invent imports or APIs without checking the pinned SDK.
- Use `var` for bindings that are reassigned. A struct method that changes fields must be declared `mut func`, and the struct instance must also be mutable.
- Keep numeric types explicit at API boundaries; do not assume implicit conversion between integer widths or between integer and floating-point types.
- Keep `unsafe` local to the smallest C-interop operation. Never guess a foreign signature, ownership rule, or library path.
- Validate tensor shapes, overflow-prone size calculations, and indices before numerical loops. Prefer a flat row-major `Array<Float64>` for an initial Tensor implementation.
- Add tests for normal behavior and at least one boundary or invalid-input case.
- Treat Windows/MinGW success as native verification, not proof of Linux portability. Run the Docker/Linux check before a release claim.
- Never hide compiler output or claim that generated code was tested when it was not.
