package state_snapshot

import std.collection.*

public struct SnapshotSeries {
    public let name: String
    public let values: Array<Int64>

    public init(name: String, values: Array<Int64>) {
        this.name = name
        this.values = copySnapshotInts(values)
    }
}

public struct StateSnapshot {
    public let version: Int64
    public let series: ArrayList<SnapshotSeries>

    public init(version: Int64, series: ArrayList<SnapshotSeries>) {
        this.version = version
        this.series = ArrayList<SnapshotSeries>()
        for (i in 0..series.size) {
            let item = series[i]
            this.series.add(SnapshotSeries(item.name, item.values))
        }
    }
}

func copySnapshotInts(values: Array<Int64>): Array<Int64> {
    let result = Array<Int64>(values.size, repeat: 0)
    for (i in 0..values.size) { result[i] = values[i] }
    return result
}

func snapshotNameValid(name: String): Bool {
    if (name.size < 1 || name.size > 16) { return false }
    let first = name[0]
    if (first < UInt8(97) || first > UInt8(122)) { return false }
    for (i in 1..name.size) {
        let byte = name[i]
        if (!((byte >= UInt8(97) && byte <= UInt8(122)) || (byte >= UInt8(48) && byte <= UInt8(57)) || byte == UInt8(95))) { return false }
    }
    return true
}

func parseSnapshotInt(text: String, minimum: Int64, maximum: Int64): (Bool, Int64) {
    if (text.size <= 0) { return (false, 0) }
    var negative = false
    var start: Int64 = 0
    if (text[0] == UInt8(45)) { negative = true; start = 1 }
    if (start >= text.size) { return (false, 0) }
    let limit = if (negative) { if (minimum < 0) { -minimum } else { 0 } } else { maximum }
    var magnitude: Int64 = 0
    for (i in start..text.size) {
        let byte = text[i]
        if (byte < UInt8(48) || byte > UInt8(57)) { return (false, 0) }
        let digit = Int64(byte - UInt8(48))
        if (magnitude > (limit - digit) / 10) { return (false, 0) }
        magnitude = magnitude * 10 + digit
    }
    if (negative) {
        if (minimum >= 0 || magnitude > -minimum) { return (false, 0) }
        return (true, -magnitude)
    }
    if (magnitude < minimum || magnitude > maximum) { return (false, 0) }
    return (true, magnitude)
}

func snapshotNameBefore(left: String, right: String): Bool {
    let common = if (left.size < right.size) { left.size } else { right.size }
    for (i in 0..common) {
        if (left[i] < right[i]) { return true }
        if (left[i] > right[i]) { return false }
    }
    return left.size < right.size
}

public func encodeState(version: Int64, series: ArrayList<SnapshotSeries>): String {
    if (version != 1 || series.size > 64) { throw IllegalArgumentException("unsupported snapshot") }
    var encoded = "CJSNAP|1|" + series.size.toString()
    if (series.size > 0) { encoded += "\n" }
    var previous = ""
    for (i in 0..series.size) {
        let item = series[i]
        if (!snapshotNameValid(item.name) || item.values.size < 1 || item.values.size > 16) {
            throw IllegalArgumentException("snapshot order or shape is invalid")
        }
        if (i > 0) { encoded += "" }
        encoded += item.name + "|" + item.values.size.toString() + "|"
        for (j in 0..item.values.size) {
            let parsed = item.values[j]
            if (parsed < -1000000000 || parsed > 1000000000) { throw IllegalArgumentException("snapshot value out of range") }
            if (j > 0) { encoded += "," }
            encoded += parsed.toString()
        }
        if (i + 1 < series.size) { encoded += "\n" }
        previous = item.name
    }
    return encoded
}

public func decodeState(text: String): StateSnapshot {
    if (text.size <= 0) { throw IllegalArgumentException("empty snapshot") }
    let lines = text.split("\n")
    if (lines.size < 1) { throw IllegalArgumentException("snapshot framing is invalid") }
    let header = lines[0].split("|")
    if (header.size != 3 || header[0] != "CJSNAP" || header[1] != "1") { throw IllegalArgumentException("snapshot header is invalid") }
    let count = parseSnapshotInt(header[2], 0, 64)
    if (!count[0] || lines.size != count[1] + 1) { throw IllegalArgumentException("snapshot record count is invalid") }
    let result = ArrayList<SnapshotSeries>()
    var previous = ""
    for (i in 0..count[1]) {
        let fields = lines[i + 1].split("|")
        if (fields.size != 3 || !snapshotNameValid(fields[0])) {
            throw IllegalArgumentException("snapshot record is invalid")
        }
        let length = parseSnapshotInt(fields[1], 1, 16)
        let pieces = fields[2].split(",")
        if (!length[0] || pieces.size != length[1]) { throw IllegalArgumentException("snapshot value count is invalid") }
        let values = Array<Int64>(length[1], repeat: 0)
        for (j in 0..length[1]) {
            let parsed = parseSnapshotInt(pieces[j], -1000000000, 1000000000)
            if (!parsed[0]) { throw IllegalArgumentException("snapshot value is invalid") }
            values[j] = parsed[1]
        }
        result.add(SnapshotSeries(fields[0], values))
        previous = fields[0]
    }
    return StateSnapshot(1, result)
}
