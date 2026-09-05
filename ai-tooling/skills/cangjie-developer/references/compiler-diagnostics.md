# Compiler-diagnostic translations

Use the first actionable diagnostic; later errors may be parser fallout. Confirm every correction by compiling.

| Diagnostic fragment | Likely cause | Focused correction |
| --- | --- | --- |
| `expected '{', found keyword 'throw'` | A control-flow body omitted braces | Write `if (condition) { throw ... }` |
| `Array` call `expected 2 arguments, found 1` | Invented one-argument size or copy constructor | Allocate with `Array<T>(size, repeat: value)` and fill by index |
| `undeclared identifier 'toFloat64'` | Java/Kotlin-style conversion was invented | Use `Float64(value)` |
| `invalid binary operator` on `Float64` and `Int64` | An integer operand was mixed with floating-point data | Use a matching floating literal, or convert a count explicitly with `Float64(count)` |
| `undeclared identifier 'self'` | Python/Rust/Swift receiver syntax leaked in | Use `this` |
| package imports `std.thread` but it is not a dependency | A nonexistent module was invented | Remove it; use `spawn` and `Future`, importing `std.collection.*` only for `ArrayList` |
| `undeclared identifier 'Math'` | Java-style math namespace was invented | Import `std.math.*` and call `sqrt`, `exp`, or `log` directly |
| `undeclared identifier 'ln'` | A conventional name not provided by the pinned SDK was assumed | Import `std.math.*` in that file and call `log(value)` |
| `undeclared identifier 'isFinite'` | A JavaScript-style floating-point helper was invented | Reject non-finite values with `value.isNaN()` and `value.isInf()` according to the contract |
| `undeclared identifier 'abs'` | An unverified overload/import was assumed | For simple floating code, compute the absolute value with an `if` expression |
| `unexpected modifier 'mut'` in a class body | The struct-only mutation modifier was copied onto a class method | Remove `mut`; class methods may change class fields without it |
| `isNone`, `unwrap`, or `get` is undeclared on a parse result | An Option-returning parser API was imagined | Import `std.convert.*`, use the scalar returned by `Int64.parse`/`Float64.parse`, and handle invalid text with exceptions |
| `substring` is not a member of `String` | A Java-style slicing API was invented | Use `split` with exact part-count/tag validation for a delimited format |
| `undeclared type name 'Char'` | A character type from another language was invented | In the verified ASCII pattern, index `String` as `UInt8` and compare numeric byte values |
| `undeclared identifier 'usize'` | A Rust-style index conversion leaked in | Keep string, array, and collection indices as `Int64` |
| invalid operator on `UInt8` and `String` | A string or quoted literal was compared with an indexed byte | Compare with `UInt8(48)`/`UInt8(57)` for digits, then convert the byte difference |
| `max`, `MAX`, or `MAX_VALUE` is undeclared on `Int64` | The integer-limit name or case was guessed | Prefer quotient/remainder checks against a known length; when a true bound is required, the pinned spelling is `Int64.Max` |

After a syntax or type fix, verify that the exact rejected token or construct no
longer remains, then rerun the narrow command. Do not respond to every
downstream error at once. If the same root cause survives three focused
attempts, preserve the evidence and report the blocker.
