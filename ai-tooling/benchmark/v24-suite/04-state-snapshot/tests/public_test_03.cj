package state_snapshot

import std.collection.*

func snapshotRejects(text: String): Unit {
    var rejected = false
    try {
        _ = decodeState(text)
    } catch (e: Exception) {
        rejected = true
    }
    if (!rejected) { throw Exception("invalid snapshot was accepted") }
}

main() {
    snapshotRejects("CJSNAP|1|2\nbeta|1|3\nalpha|1|4")
    snapshotRejects("CJSNAP|1|2\nalpha|1|3\nalpha|1|4")
    snapshotRejects("CJSNAP|1|1\nalpha|1|3\n")
    let unsorted = ArrayList<SnapshotSeries>()
    unsorted.add(SnapshotSeries("zeta", [1]))
    unsorted.add(SnapshotSeries("eta", [2]))
    var rejectedEncode = false
    try {
        _ = encodeState(1, unsorted)
    } catch (e: Exception) {
        rejectedEncode = true
    }
    if (!rejectedEncode) { throw Exception("unsorted snapshot was encoded") }
}
