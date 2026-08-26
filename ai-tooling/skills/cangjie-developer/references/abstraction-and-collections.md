# Types, abstraction, and collections

Use this reference when designing reusable Cangjie APIs. Confirm uncertain details with Cangjie 1.1.3 rather than importing Java, Kotlin, Rust, or Python habits.

## Struct, class, and interface

- Use `struct` for small value-like data. Mutating a field requires `mut func`, and the receiving binding must be `var`.
- Use `class` when reference identity, shared mutable state, or class inheritance is intentional. A class method does not use `mut` merely because it changes a field.
- Use `interface` for behavior contracts. Interface members have public semantics; an implementation must expose the implemented member as `public`.
- A class implements or inherits types with `<:`. Multiple interfaces are joined with `&`.
- Do not add inheritance only to reuse code. Prefer a small interface at an actual substitution boundary.

```cangjie
interface Transform {
    func apply(value: Float64): Float64
}

class Scale <: Transform {
    let factor: Float64

    public init(factor: Float64) {
        this.factor = factor
    }

    public func apply(value: Float64): Float64 {
        value * factor
    }
}
```

## Generics and extensions

- Put generic constraints in a `where` clause, such as `where T <: SomeInterface`.
- Do not assume generic numeric arithmetic is available merely because `T` looks number-like; require an interface that provides each used operation or implement concrete numeric types first.
- Use an extension to add behavior when the type is not under your control or when a coherent capability belongs outside its original declaration. Avoid using extensions to hide an unclear architecture.

## Collection choice

- `Array<T>`: fixed length, mutable elements, ordered; a good default for dense numerical storage.
- `ArrayList<T>`: ordered and resizable; use when elements are frequently added or removed.
- `HashSet<T>`: unique, unordered elements.
- `HashMap<K, V>`: key-value lookup; do not rely on iteration order.

Copy mutable collections at API boundaries when ownership must be independent. Document deliberate sharing instead of letting it happen accidentally.

## Visibility and API design

Start with the narrowest visibility that supports the package design. Mark only intended external API as `public`; keep representation fields private when invariants depend on controlled access.

## Official references

- [Classes](https://cj-docs.gitcode.com/zh/1.1.3/dev-guide/source_zh_cn/class_and_interface/class.html)
- [Interfaces](https://cj-docs.gitcode.com/zh/1.1.3/dev-guide/source_zh_cn/class_and_interface/interface.html)
- [Collection overview](https://cj-docs.gitcode.com/zh/1.1.3/dev-guide/source_zh_cn/collections/collection_overview.html)
