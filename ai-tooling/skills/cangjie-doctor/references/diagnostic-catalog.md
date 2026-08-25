# Cangjie diagnostic catalog

Use exact compiler text as evidence. These are routing hints, not replacements for reading the source line.

| Diagnostic fragment | Likely cause | First check |
| --- | --- | --- |
| `mismatched types` | Declared and produced types differ | Function return type, literal type, and expression operands |
| `cannot be modified in immutable function` | A struct method changes a field without `mut func` | Mark the struct method mutable if mutation is intended |
| `cannot assign to immutable value` | Assignment targets a `let` binding or immutable field | Decide whether it should be `var`; do not change blindly |
| `undeclared identifier` | Misspelling, missing import, or wrong scope | Exact identifier, imports, and declaration scope |
| `expected` near parser output | Syntax is incomplete or invalid | Earliest parser error, preceding brace, comma, and type annotation |
| `failed to compile package` | Wrapper message | Read earlier compiler diagnostics; this is rarely the root cause |
| test summary contains `FAILED` | Behavior differs from a test expectation | First failing case and its assertion output |

## Triage order

1. SDK executable or runtime library missing.
2. Manifest and package-layout problem.
3. Earliest parser error.
4. Earliest type or mutability error.
5. Linker error.
6. First failing unit test.

One source mistake may emit many diagnostics. For example, immutable struct fields changed inside a non-mutable method can produce both `cannot be modified in immutable function` and `cannot assign to immutable value`. Describe the combined correction, but still cite the first actionable location.

## Plain-language translation

Prefer: “函数声明说会返回整数，但计算结果是小数；让声明和结果使用同一种类型。”

Avoid: “发生 nominal type mismatch due to incompatible return-expression typing.”
