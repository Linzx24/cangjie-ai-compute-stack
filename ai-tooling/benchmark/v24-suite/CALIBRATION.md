# v24 public calibration

Calibration was performed against the installed Cangjie native toolchain:

```text
cjc: Cangjie Compiler 1.1.3 (cjnative), x86_64-w64-mingw32
cjpm: Cangjie Project Manager 1.1.3
target: cjnative-x86_64-w64-mingw32
dependencies: none
model calls: 0
```

Each public test was compiled as its own native executable with the task's
single starter source, run, then repeated with an independently authored
reference source under the private authoring area. Each starter was also
built with `cjpm build`. The checked-in starter is intentionally incomplete;
the reference is not part of the public tree and is not listed in the public
manifest.

| Task | Starter public pass | Reference public pass | Starter calibration witness |
| --- | ---: | ---: | --- |
| 01-windowed-attention | 2/4 | 4/4 | diagonal-only starter fails cross-window mixing |
| 02-softmax-trainer | 2/4 | 4/4 | candidate gradients are calculated but not committed |
| 03-event-batch-parser | 3/4 | 4/4 | staged rows leak when a later row is malformed |
| 04-state-snapshot | 3/4 | 4/4 | starter omits strict increasing-name validation |
| **Total** | **10/16** | **16/16** | meaningful incompleteness in every starter |

The reference results were obtained with the same four public tests and
without hidden tests. Compilation and execution failures were treated as
test failures; no result was inferred from source inspection. Calibration
artifacts were removed after each run by
`scripts/Cleanup-CalibrationArtifacts.ps1`. The public validator then checked
the exact tree inventory, API patterns, SHA-256 records, forbidden-artifact
boundary, and aggregate reproducibility.

No hidden tests, private results, historical outcome files, or model calls
were read or created for this suite.
