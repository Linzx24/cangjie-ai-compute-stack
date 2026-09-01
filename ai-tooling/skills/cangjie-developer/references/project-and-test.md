# Cangjie project and test workflow

## Project boundary

Run `cjpm` from the directory containing `cjpm.toml`. Read the manifest before
assuming a module name, output type, dependency, or source layout. Package
declarations must follow the repository's working files.

A small package commonly has:

```text
cjpm.toml
src/
  implementation.cj
  implementation_test.cj
```

## Verification

```powershell
cjpm build
cjpm test --no-color
```

Use `cjpm check` or `cjpm tree` only for dependency diagnosis. Use `cjc` in a
temporary directory for an uncertain one-file syntax experiment. Do not leave
generated binaries in the source tree.

Follow the package's existing `std.unittest` imports and test macros. Numerical
tests should include a small known answer, invalid shapes or indices, exact
endpoints, and tolerance-based floating comparisons where results are not exact.

## Stateful integration tests

Component tests do not replace the public workflow that composes them.

- Call every changed public entry point.
- Execute at least two state transitions.
- Cross one relevant empty, reset, wrap, capacity, exhaustion, corruption, or
  fallback boundary.
- Check shape and a conservation or normalization property.
- Snapshot all public observables and verify a rejected call changes none.
- Verify returned arrays or snapshots do not alias internal mutable storage.

## Diagnostic loop

1. Record the command, exit code, and first actionable diagnostic.
2. Classify it as syntax, type, package, linker, runtime, or test failure.
3. Make one focused correction.
4. Rerun the narrow failure, then the full build and tests.

Windows SDK success proves that native target only; it is not Linux,
accelerator, or performance evidence. Before a release claim, test from a clean
checkout or clean build context and record the pinned compiler version.

Official reference: [cjpm manual](https://cj-docs.gitcode.com/zh/1.1.3/tools/source_zh_cn/cmd-tools/cjpm_manual.html).
