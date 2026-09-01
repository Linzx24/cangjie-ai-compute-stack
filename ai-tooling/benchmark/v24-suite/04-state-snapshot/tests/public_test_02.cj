package state_snapshot

import std.collection.*

main() {
    let text = "CJSNAP|1|2\nalpha|2|3,-4\nbeta|1|7"
    let decoded = decodeState(text)
    if (decoded.version != 1 || decoded.series.size != 2 || decoded.series[0].name != "alpha" || decoded.series[0].values[1] != -4 || decoded.series[1].values[0] != 7) {
        throw Exception("snapshot decode mismatch")
    }
    if (encodeState(decoded.version, decoded.series) != text) { throw Exception("snapshot round trip mismatch") }
}
