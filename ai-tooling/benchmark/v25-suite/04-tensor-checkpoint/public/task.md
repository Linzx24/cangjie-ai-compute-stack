# Transactional tensor checkpoint store

Implement starter/src/tensor_checkpoint.cj for Cangjie 1.1.3 using only the
standard library. Preserve the public API and do not add a main function.
Each evaluator test is a separate native program.

The API is:

    TensorRecord(
        name: String, rows: Int64, columns: Int64, values: Array<Float64>
    )
    CheckpointView(step: Int64, tensors: ArrayList<TensorRecord>)
    TensorCheckpointStore(step: Int64, tensors: ArrayList<TensorRecord>)
    snapshot(): CheckpointView
    encode(): String
    restore(text: String): Unit

step is in 0..1000000000. A store has at most 16 tensors. Names are one to
sixteen strict ASCII characters matching [a-z][a-z0-9_]* and must be strictly
increasing in bytewise order. Dimensions are positive. Each tensor has 1..1024
finite values and rows * columns must match that length; validate the match
with division and remainder before multiplying.

Construction, snapshots, and restore copy the list and every nested values
array. Mutating caller data or a returned snapshot must not affect the store.

Use this exact UTF-8 format with no terminal newline:

    CJTENSOR|1|<step>|<tensor-count>
    <name>|<rows>|<columns>|<value>[,<value>...]

The first line is the header and each following line is one tensor. Nonnegative
integers are canonical base-10: zero is "0", otherwise there are no leading
zeroes. A Float64 value is canonical only when parsing it and calling the
standard toString() reproduces the exact token. encode uses that same
toString(). Reject unsupported versions, malformed or extra fields, a wrong
line or value count, noncanonical numbers, NaN, infinity, duplicate or
unsorted names, trailing newlines, and all other contract violations with
IllegalArgumentException.

restore is transactional. Parse and validate a complete independently owned
candidate before changing step or tensors. On failure every observable stays
unchanged. A successful encode/restore/encode round trip is byte-identical.
