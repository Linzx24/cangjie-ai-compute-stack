---
name: cangjie-doctor
description: Diagnose Cangjie 1.1.3 environment, cjpm build, compiler, linker, and unit-test failures using reproducible command evidence. Use when a Cangjie project does not compile, tests fail, the SDK is missing or misconfigured, or a user asks for a Cangjie health check. Do not use to implement unrelated features or silently modify source code when only diagnosis was requested.
---

# Cangjie Doctor

Find the first actionable root cause and explain it in plain language. Treat later diagnostics as possible consequences until proven independent.

## Diagnostic workflow

1. Locate the nearest `cjpm.toml` and read repository instructions. Do not edit code during a diagnosis-only request.
2. Run `scripts/diagnose.ps1 -ProjectPath <project>` on Windows. Pass `-SdkRoot` when `CANGJIE_HOME` is unavailable. Add `-RunTests` when the build succeeds or the reported problem involves tests.
3. Preserve the exact command, exit code, first useful diagnostic, file, line, and compiler version.
4. Read [diagnostic-catalog.md](references/diagnostic-catalog.md) only when classification or next steps are uncertain.
5. Reproduce with the narrowest command that still fails. Do not guess from screenshots when the project can be checked directly.
6. Report:
   - what passed;
   - what failed;
   - the first likely root cause;
   - the smallest proposed correction;
   - what command should verify the correction.
7. Apply a fix only if the user requested implementation. After a fix, run `cjpm build` and `cjpm test --no-color`.

## Guardrails

- Target the version pinned by the repository; otherwise use Cangjie 1.1.3.
- Do not suppress diagnostics or report success from a zero-output assumption.
- Do not blame the final `cjpm build failed` wrapper when an earlier compiler message names the real cause.
- If the same hypothesis fails three focused attempts, stop changing code and report the evidence and remaining uncertainty.
- Separate environment failures, compilation failures, and test failures; they require different next actions.
