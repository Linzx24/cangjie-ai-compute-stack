# v25 coverage and novelty

The four tasks exercise independent CPU-only, standard-library contracts:

| Task | Capability | Coupled dimensions/state | Public witnesses |
| --- | --- | --- | --- |
| 01-masked-smoothing | stable softmax and log-normalizer, label smoothing, masking, mean gradients | row × class values with active-row reduction | unsmoothed known answer; smoothed target; masked-row zeroing and active divisor; translation stability and invalid inputs |
| 02-gradient-window | gradient accumulation, mean reduction, norm clipping, transactional updates | microbatch samples × parameter state across calls | complete-window update; partial then complete transition; clipping; rejection rollback, ownership, and reset |
| 03-beam-frontier | compiler-guided collection repair, deterministic top-k selection | parent × vocabulary candidates across steps | single-parent ranking; tie order; two-step multi-parent expansion; rejection rollback, ownership, and reset |
| 04-tensor-checkpoint | strict parsing, canonical serialization, deep ownership, transactional restore | tensor list × shapes × nested values | canonical bytes; restore round trip; malformed restore rollback; constructor and snapshot isolation |

The first two tasks focus on numerical training primitives. The third combines
a small compiler diagnostic with stateful search logic. The fourth covers
deterministic model-state I/O. Public API names and task contracts are new to
this suite.

Every task has exactly one replaceable source and four independently compiled
public tests. Across the suite the tests include known answers, invalid
boundaries, multi-step state transitions, transactional rejection, numerical
stability, deterministic ordering, and deep-copy ownership.
