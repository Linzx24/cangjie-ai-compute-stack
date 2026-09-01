package state_snapshot

import std.collection.*

main() {
    let values = [5, 6]
    let series = ArrayList<SnapshotSeries>()
    series.add(SnapshotSeries("gamma", values))
    let text = encodeState(1, series)
    values[0] = 99
    series[0] = SnapshotSeries("gamma", [8, 9])
    if (text != "CJSNAP|1|1\ngamma|2|5,6") { throw Exception("snapshot encode aliases input") }
    let decoded = decodeState(text)
    decoded.series[0].values[0] = 77
    if (decodeState(text).series[0].values[0] != 5) { throw Exception("snapshot decode aliases parser state") }
    let empty = ArrayList<SnapshotSeries>()
    if (encodeState(1, empty) != "CJSNAP|1|0" || decodeState("CJSNAP|1|0").series.size != 0) {
        throw Exception("snapshot empty state mismatch")
    }
}
