# Deterministic state snapshots

Implement `starter/src/state_snapshot.cj` for Cangjie 1.1.3 using only the
standard library. This is a single-file deterministic serialization task; the
evaluator compiles the file with each public test and supplies no other
project source.

Expose these declarations:

```text
SnapshotSeries(name: String, values: Array<Int64>)
StateSnapshot(version: Int64, series: ArrayList<SnapshotSeries>)
encodeState(version: Int64, series: ArrayList<SnapshotSeries>): String
decodeState(text: String): StateSnapshot
```

The only supported version is `1`. A series name is one to sixteen strict
ASCII characters matching `[a-z][a-z0-9_]*`; names in a snapshot must be
strictly increasing in bytewise ASCII order. Each series has one to sixteen
values, each in `-1000000000..1000000000`. Reject unsupported versions, bad
names, duplicate or unsorted names, invalid values, and more than 64 series.

Use this exact canonical UTF-8 text format, with no terminal newline:

```text
CJSNAP|1|<series-count>\n
<name>|<value-count>|<decimal-value>[,<decimal-value>...]
```

The header is one line and each following line is one record. Decimal values
are base-10 integers with an optional leading minus sign and no other
characters. `encodeState` must validate the complete input before returning a
canonical string. `decodeState` must require the exact line count, parse all
records, and reject truncation, extra lines, malformed framing, and trailing
newlines. The returned snapshot and every values array must be independent
copies; a failed decode has no state to publish. Encoding a decoded snapshot
must reproduce the identical text.
