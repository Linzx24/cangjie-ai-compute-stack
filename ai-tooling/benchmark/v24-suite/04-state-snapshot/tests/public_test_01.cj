package state_snapshot

import std.collection.*

main() {
    let series = ArrayList<SnapshotSeries>()
    series.add(SnapshotSeries("alpha", [3, -4]))
    series.add(SnapshotSeries("beta", [7]))
    let encoded = encodeState(1, series)
    let expected = "CJSNAP|1|2\nalpha|2|3,-4\nbeta|1|7"
    if (encoded != expected) { throw Exception("snapshot canonical encoding mismatch") }
}
