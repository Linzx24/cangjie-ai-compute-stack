# Cangjie 1.1.3 language notes

Use these notes as a compact reminder, then let `cjc` decide disputed syntax.

## Bindings, loops, and arrays

- `let` creates an immutable binding; `var` creates a binding that may be reassigned.
- A half-open range such as `0..size` visits `0` through `size - 1`.
- Construct a filled array with `Array<T>(size, repeat: value)`.
- Access tuple elements by numeric member, for example `pair[0]` and `pair[1]`.

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

## Option and generics

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

## Diagnostic order

When many errors appear, start with the earliest parser or type error. Later messages are often consequences.

Common checks:

1. Confirm the package declaration and file location.
2. Confirm braces and declared return types.
3. Check `let` versus `var`, and `mut func` for struct mutation.
4. Check integer types used for sizes and indices.
5. Reduce uncertain syntax to a tiny `.cj` program and compile it before applying it broadly.
