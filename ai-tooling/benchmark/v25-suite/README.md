# Cangjie v25 public benchmark

This is a four-task, CPU-only benchmark for Cangjie 1.1.3. Each task is
standalone and dependency-free. The candidate replaces exactly one
`starter/src/*.cj` file, and each public test is compiled with that source as
a separate native program.

The suite covers four distinct implementation contracts:

1. `01-masked-smoothing` implements stable masked label-smoothed cross
   entropy, probabilities, and mean gradients.
2. `02-gradient-window` implements transactional microbatch accumulation,
   norm clipping, parameter updates, and reset behavior.
3. `03-beam-frontier` repairs a local Cangjie collection error and implements
   deterministic multi-parent beam selection.
4. `04-tensor-checkpoint` implements an owned, canonical, transactional
   tensor checkpoint store.

`public-suite.json` is the closed machine-readable manifest and
`suite.schema.json` describes its schema. `COVERAGE.md` records public
capability witnesses. `CALIBRATION.md` records the checked-in starter baseline
and the independently compiled reference baseline.

Validate the exact public inventory, paths, API witnesses, SHA-256 records,
and reproducible aggregate with:

```powershell
pwsh -NoProfile -File .\scripts\Validate-V25PublicSuite.ps1
```

Run starter builds and all sixteen public tests with explicit Cangjie 1.1.3
executables:

```powershell
$cjpm = (Get-Command cjpm -CommandType Application -All | Select-Object -First 1).Source
$cjc = (Get-Command cjc -CommandType Application -All | Select-Object -First 1).Source
pwsh -NoProfile -File .\scripts\Invoke-PublicCalibration.ps1 -CjpmPath $cjpm -CjcPath $cjc
```

The third starter intentionally contains a documented local compiler error.
Calibration records that build and its test compilations as failures, then
continues through the remaining tasks. Generated `x`, `target`, `t`, `build`,
`cjpm.lock`, and native binaries are removed in a `finally` block.

The manifest excludes `public-suite.json` from its file records. Its
aggregate is the lowercase SHA-256 of UTF-8 LF-ended lines containing the
manifest digest followed by ordinal-sorted path/tab/declared-digest records.
Reversing record insertion order must reproduce the same aggregate.
