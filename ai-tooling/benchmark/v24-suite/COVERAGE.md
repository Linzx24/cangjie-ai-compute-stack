# v24 coverage and novelty

The four tasks exercise distinct contracts while staying dependency-free and
CPU-only:

| Task | Capability | Coupled dimensions/state | Public witnesses |
| --- | --- | --- | --- |
| 01-windowed-attention | tensor shape validation, local softmax, row-major reductions, ownership | token × token × feature attention | one-token identity; two-token weighted answer; invalid shape; cross-window and input-copy behavior |
| 02-softmax-trainer | minibatch objective, stable softmax, SGD, state transitions | batch × feature × class gradient coupling | one-row known update; two-row mean gradient and prediction; rejected update rollback; accessor isolation and reset |
| 03-event-batch-parser | strict ASCII and bounded decimal parsing | variable-length rows × bounded log capacity | scalar row; multi-value rows; malformed-row atomicity; capacity and reset |
| 04-state-snapshot | canonical framing, deterministic order, integer codec, ownership | series × values with exact line counts | canonical bytes; round-trip; duplicate/order/trailing-line rejection; input/decode copy isolation |

The first two are deliberately multi-dimensional ML implementations. The
third is a local non-ML parser with variable-length records. The fourth is a
pure deterministic state/serialization component. None reuses masked
normalization, a gradient accumulator, ASCII run-length encoding, or a
loss-scaled optimizer, and all public API names are new to this suite.

Every task has exactly one replaceable source and four independently compiled
public tests. Public tests cover at least one valid known answer, a boundary
or rejection, a state transition where applicable, and a copy/ownership
property.
