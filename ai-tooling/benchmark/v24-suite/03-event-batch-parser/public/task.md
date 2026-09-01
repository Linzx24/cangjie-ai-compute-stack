# Atomic variable-length event batches

Implement the single source file `starter/src/event_batch_parser.cj` for
Cangjie 1.1.3. It is a local, non-ML data-processing task: no dependencies,
no `main`, and no extra files. Every public test compiles the source in a
fresh native process.

The required declarations are:

```text
EventRecord(id: Int64, timestamp: Int64, name: String, values: Array<Int64>)
BatchResult(added: Int64, rejectedLine: Int64, totalRecords: Int64, totalValues: Int64)
EventLog(capacity: Int64)
size(): Int64
totalValues(): Int64
records(): ArrayList<EventRecord>
reset(): Unit
appendBatch(text: String): BatchResult
```

The input is a non-empty sequence of lines separated by `\n`; a terminal
newline therefore creates a rejected empty line. Each line has exactly three
fields separated by `#`: a timestamp, a name, and a comma-separated list of
one to eight signed decimal values. Timestamps are integers in
`0..2147483647`, must be strictly greater than the last committed timestamp,
and names are one to twelve ASCII characters matching
`[a-z][a-z0-9_]*`. Values are in `-1000000..1000000`; reject empty fields,
non-ASCII names, malformed digits, and overflow. The capacity is positive and
limits the number of records.

Parsing is transactional. Stage and validate every line, including the
timestamp order and final capacity, before changing the log. On success,
assign consecutive one-based IDs, append lines in input order, and return
`added` equal to the line count, `rejectedLine == 0`, and current totals. On
failure return `added == 0` and the one-based malformed line (or `0` for a
capacity rejection); `totalRecords` and `totalValues` report the unchanged
state. A rejected call must not consume IDs or timestamps. `records()` must
return an independent list with independent value arrays. `reset()` clears
records and totals and restarts IDs and timestamp validation.
