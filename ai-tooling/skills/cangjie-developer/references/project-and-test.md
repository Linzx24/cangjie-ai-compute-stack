# Cangjie project and test workflow

## Locate the project boundary

Run `cjpm` from the directory containing `cjpm.toml`. Inspect that file before assuming a module name or source layout.

A small executable project commonly contains:

```text
cjpm.toml
src/
  main.cj
src/tests/
  *_test.cj
```

Package declarations must agree with the module and directory organization already used by the repository. Follow the repository's working example instead of inventing a parallel layout.

## Verification commands

```powershell
cjpm build
cjpm test --no-color
```

Use `cjpm check` or `cjpm tree` when dependency resolution is the suspected problem. Use `cjpm bench` for a benchmark declared with the official test/benchmark facilities; a unit test is not a performance measurement.

For an uncertain one-file syntax experiment, use `cjc` in a temporary directory. Do not leave generated binaries in the source tree.

## Unit-test pattern

Follow the imports and macros already present in the repository. A typical Cangjie test uses `std.unittest` assertions and `@Test` declarations. Test names should describe behavior rather than implementation.

For numerical code, cover:

- a small hand-computable example;
- zeros and negative values when relevant;
- mismatched shapes or invalid indices;
- floating-point comparisons with a tolerance when results are not exact.

## Compiler-diagnostic loop

1. Capture the command, exit code, and first actionable diagnostic.
2. Identify whether it is syntax, type, package, linker, or runtime/test failure.
3. Make one focused correction.
4. Rerun the narrowest failing command, then the full build and test suite.
5. If the same root cause remains after three focused attempts, report the exact blocker and the experiments already tried.

## Platform meaning

- Windows SDK success proves the native MinGW build works.
- Linux SDK success in Docker checks a second toolchain and repeatability.
- Neither result alone proves numerical performance or accelerator support; benchmark those separately.

## Dependency and release checks

- Read `cjpm.toml` and `cjpm.lock` before changing a dependency.
- Pin the compiler requirement with `cjc-version` and respect target-specific dependency/FFI sections.
- Do not disable TLS verification to work around a dependency download failure.
- Before a release claim, run tests from a clean checkout or clean build context so ignored local artifacts cannot make the result pass accidentally.

Official reference: [cjpm manual](https://cj-docs.gitcode.com/zh/1.1.3/tools/source_zh_cn/cmd-tools/cjpm_manual.html).
