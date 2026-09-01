# Cangjie 1.1.3 language-core notes

Use these notes as a compact reminder, then let `cjc` decide disputed syntax.

## Bindings, loops, and arrays

- `let` creates an immutable binding; `var` creates a binding that may be reassigned.
- A half-open range such as `0..size` visits `0` through `size - 1`.
- Construct a filled array with `Array<T>(size, repeat: value)`.
- Access tuple elements by numeric member, for example `pair[0]` and `pair[1]`.
- Always write braces around control-flow bodies. `if (condition) { throw ... }` is valid; `if (condition) throw ...` is not.

```cangjie
func relu(values: Array<Float64>): Array<Float64> {
    let result = Array<Float64>(values.size, repeat: 0.0)
    for (i in 0..values.size) {
        result[i] = if (values[i] > 0.0) { values[i] } else { 0.0 }
    }
    return result
}
```

The array contents are mutable even when the array reference is held by `let`; use `var` only when rebinding the variable itself.

Array length and ordinary indices are `Int64` in the tested 1.1.3 APIs. Keep numeric types explicit when mixing `Int32`, `Int64`, `UInt64`, `Float32`, and `Float64`. Floating-point expressions require floating-point literals: use `2.0 * epsilon` and `epsilon <= 0.0`, not `2 * epsilon` or `epsilon <= 0`. Convert an integer count with `Float64(count)`; do not invent a method such as `count.toFloat64()`. If other conversion syntax is uncertain, compile a tiny example rather than guessing.

Cangjie uses `this`, not `self`, for the current instance. Use an `if` expression for conditional values; do not import the C-style `condition ? left : right` operator from another language.

## Strings and strict ASCII

In the tested 1.1.3 SDK, indexing a `String` yields a `UInt8` and uses an
`Int64` index. Do not write `Char`, `usize`, or Java-style `substring`.
Prefer exact delimiter parsing with `split`; when a byte-level ASCII grammar is
required, use numeric byte values.

```cangjie
func parseAsciiDigit(byte: UInt8): Int64 {
    if (byte < UInt8(48) || byte > UInt8(57)) {
        throw IllegalArgumentException("digit")
    }
    return Int64(byte - UInt8(48))
}
```

Use `UInt8(97)..UInt8(122)` for lowercase ASCII letters. Validate the full
string before mutating state, and compile a probe before assuming another
Unicode or slicing API.

## Functions, Lambda, and closures

- A function type is written like `(Int64, Int64) -> Int64`.
- A Lambda uses `{parameters => body}`. Even a parameterless Lambda needs `=>`, except where trailing-Lambda syntax permits omission.
- Lambda return types are inferred; do not write a return-type annotation inside the Lambda parameter list.

```cangjie
func applyTwice(value: Int64, operation: (Int64) -> Int64): Int64 {
    return operation(operation(value))
}

let increment: (Int64) -> Int64 = {value => value + 1}
let result = applyTwice(3, increment)
```

## Struct and class mutation

A struct method that modifies one of its fields needs `mut func`. The receiving struct binding must be `var`.

```cangjie
struct Counter {
    var value: Int64

    public init(value: Int64) {
        this.value = value
    }

    public mut func increment(): Unit {
        value++
    }
}

var counter = Counter(0)
counter.increment()
```

Do not add `mut` to an ordinary class method merely because it changes a class field.

## Option, enum, and pattern matching

Use `Option<T>`, `Some(value)`, and `None`. The shorthand `?T` also denotes an optional value where supported by the surrounding declaration.

```cangjie
func safeDivide(a: Float64, b: Float64): Option<Float64> {
    if (b == 0.0) {
        return None
    }
    return Some(a / b)
}

func swap<T, U>(pair: (T, U)): (U, T) {
    return (pair[1], pair[0])
}
```

Use `match` when the caller must handle every enum branch. Do not force an `Option` value without first proving it is `Some`.

```cangjie
func valueOr(option: Option<Int64>, fallback: Int64): Int64 {
    match (option) {
        case Some(value) => value
        case None => fallback
    }
}
```

## Exceptions

- Throw `Exception` subclasses for recoverable application failures; do not define application exceptions by inheriting from `Error`.
- Prefer `Option` when absence is an expected result. Use an exception when the operation cannot fulfill its contract.
- Catch the narrowest useful exception first. Preserve the original exception as the cause when translating it.

## Diagnostic order

When many errors appear, start with the earliest parser or type error. Later messages are often consequences.

Common checks:

1. Confirm the package declaration and file location.
2. Confirm braces and declared return types.
3. Check `let` versus `var`, and `mut func` for struct mutation.
4. Check integer types used for sizes and indices.
5. Reduce uncertain syntax to a tiny `.cj` program and compile it before applying it broadly.

## Official references

- [Functions and Lambda](https://cj-docs.gitcode.com/zh/1.1.3/dev-guide/source_zh_cn/function/lambda.html)
- [Exceptions](https://cj-docs.gitcode.com/zh/1.1.3/dev-guide/source_zh_cn/error_handle/exception_overview.html)
