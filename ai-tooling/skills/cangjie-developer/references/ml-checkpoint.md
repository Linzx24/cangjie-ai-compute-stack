# Deterministic checkpoints and file I/O

Read this reference for save/load, serialization, model state, versioned files,
or corrupted input. Parse into temporary owned state and publish only after the
whole document is valid.

## Format contract

- Specify a magic header, version, exact record count, stable record order,
  unique names, dimensions, and declared value lengths.
- Reject unsupported versions, duplicate names, mismatched lengths/shapes,
  malformed or non-finite numbers, truncated records, and unexpected trailing
  records. Keep failure precedence deterministic when errors have distinct APIs.
- Encode records in stable order. Require a canonical round-trip such as
  `encode(decode(encode(state))) == encode(state)`.
- When canonical encoding needs sorting, sort an owned copy during `encode`;
  do not silently reorder state observed through an indexed accessor unless the
  public contract explicitly defines that order.
- Copy arrays on construction, access, and decode. Loading invalid data must not
  mutate an existing model or expose a partial object.
- Guard framing arithmetic as well as tensor arithmetic. After validating the
  minimum line count, prefer comparing a declared record count with
  `lines.size - fixedFramingLines` instead of evaluating an unchecked
  `declaredCount + fixedFramingLines`.

When positive dimensions must match a known value count, validate with division
and remainder before multiplying. This avoids both overflow and guessed integer
limit APIs:

```cangjie
func dimensionsMatchLength(rows: Int64, columns: Int64, length: Int64): Bool {
    if (rows <= 0 || columns <= 0 || length < 0) {
        return false
    }
    return length % columns == 0 && length / columns == rows
}
```

If an independent upper-bound check is actually required, Cangjie 1.1.3 spells
the constant `Int64.Max` exactly. Do not invent `Int64.max`, `Int64.MAX`, or
`Int64.MAX_VALUE`.

## Cangjie 1.1.3 I/O patterns

Use `import std.fs.*`. `File(path, Write)` opens for replacement rather than
append; close it in `finally`. Read complete bytes with `File.readFrom(path)` and
decode UTF-8 with `String.fromUtf8(bytes)`.

```cangjie
let file = File(path, Write)
try {
    file.write(content.toArray())
} finally {
    file.close()
}
let content = String.fromUtf8(File.readFrom(path))
```

`Float64.parse(text)` and `Int64.parse(text)` are extension methods. Import
`std.convert.*` before using them. They return the parsed scalar directly and
throw on invalid text; do not call imagined `isNone`, `unwrap`, or `get` methods
on the result. Reject parsed floating values with `isNaN()` or `isInf()` when
the format requires finite numbers.

`String.split` is available for simple line/field formats. For a tagged field
such as `count=3`, split on `=` and validate the exact two parts, tag, and
non-empty value before parsing. Do not invent a `String.substring` method in
the pinned SDK. Keep private fields behind an accessor even in a helper outside
their class.

The patterns above are compiler-tested in the pinned SDK; they do not replace
format validation, atomic publication, or tests for filesystem exceptions.
