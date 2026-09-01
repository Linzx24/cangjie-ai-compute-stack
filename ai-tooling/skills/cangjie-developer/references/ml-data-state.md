# ML data and cache state

Read this reference for samplers, masked or ragged batches, cursors, epochs,
streaming state, and bounded caches.

## State-machine contract

- List every state field and transition before coding: size/capacity, cursor,
  epoch, deterministic order or seed, valid length, and reset behavior.
- Validate a request before changing any field. A rejected transition preserves
  counters, arrays, order, cache length, and previously returned snapshots.
- A successful transition advances each counter exactly once. At exhaustion or
  capacity, wrap, return a documented terminal result, or reject before write;
  never let an invalid cursor reach an accessor.
- `reset` restores every documented state field, not only the visible cursor.
  Exercise two transitions and deliberately cross one boundary.

## Transactional text batches

- Treat parsing as a candidate-state phase. Split only on contract delimiters,
  require the exact field count, validate every row and same-batch duplicate,
  and check final capacity before appending anything to live state.
- In Cangjie 1.1.3, `text[index]` is a `UInt8` and `index` is `Int64`.
  There is no `Char`, `usize`, or `String.substring` in the verified pattern.
  For strict ASCII, compare bytes with numeric values: digits are
  `UInt8(48)..UInt8(57)` and lowercase letters are
  `UInt8(97)..UInt8(122)`. Convert a digit with
  `Int64(byte - UInt8(48))`.
- For line-oriented formats, decide terminal-newline behavior explicitly.
  `split("\n")` and `split("\t")` are useful only after enforcing empty-line,
  carriage-return, and exact-column rules. Parse bounded decimal fields only
  after checking empty text, leading zeroes, digit bytes, and overflow/bounds.
- Stage owned records with their future IDs. On the first rejected row, return
  its one-based line number and discard the stage; on success, append the whole
  stage in order so counters and IDs advance exactly once.

## Ragged and masked data

- Store the physical shape and logical lengths separately. Validate each length
  in the contract's closed interval before computing an index.
- Mask padding in every reduction. Define mean, max, and last-value behavior for
  a zero-length sequence instead of inheriting it from loop initialization.
- Use flat row-major indexing consistently and copy caller-owned nested or flat
  arrays to the depth promised by the public API.

## Bounded caches

- Validate key/value shapes, finite values, and remaining capacity before an
  append. Compute an attention result only from the committed prefix.
- Stable softmax subtracts the row maximum before `exp`; validate the finite,
  positive denominator before normalization.
- Snapshots are independent copies. Repeated reads, failed appends, and reset
  must not expose partially written entries.
