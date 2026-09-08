# v25 public calibration

Public calibration used the installed Cangjie native toolchain:

```text
cjc: Cangjie Compiler 1.1.3 (cjnative), x86_64-w64-mingw32
cjpm: Cangjie Project Manager 1.1.3
target: cjnative-x86_64-w64-mingw32
dependencies: none
model calls: 0
```

Each public test was compiled as its own native executable with the task's
single source. A compile or execution failure counts as a failed test and does
not stop later tasks. The independently authored reference source was compiled
against the same public tests but is not part of this public tree.

| Task | Starter build | Starter public pass | Reference public pass | Starter calibration witness |
| --- | ---: | ---: | ---: | --- |
| 01-masked-smoothing | PASS | 2/4 | 4/4 | intentionally incomplete numerical behavior |
| 02-gradient-window | PASS | 2/4 | 4/4 | intentionally incomplete state transitions |
| 03-beam-frontier | FAIL | 0/4 | 4/4 | documented compiler repair plus incomplete search behavior |
| 04-tensor-checkpoint | PASS | 2/4 | 4/4 | intentionally incomplete ownership and restore behavior |
| **Total** | **3/4** | **6/16** | **16/16** | meaningful incompleteness in every starter |

The task-03 starter build failure is intentional and is stated in its public
prompt. `Invoke-PublicCalibration.ps1` therefore records build status, counts
each failed test compilation, and completes the whole matrix instead of
throwing on that starter build.

Calibration artifacts were removed after the run by
`scripts/Cleanup-CalibrationArtifacts.ps1`. The public validator checks the
exact tree inventory, API patterns, SHA-256 records, forbidden-artifact
boundary, and aggregate reproducibility. This public calibration did not read
hidden tests, private results, historical outcome files, or reference source.
The calibration command fails if the checked-in starter drifts from the
recorded 3/4 build and 6/16 public-test result. The separately authored
reference source is intentionally not published, so its recorded 16/16 result
is evidence for suite construction rather than a public rerun artifact.
