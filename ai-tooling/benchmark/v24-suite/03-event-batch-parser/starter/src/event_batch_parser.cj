package event_batch_parser

import std.collection.*

public struct EventRecord {
    public let id: Int64
    public let timestamp: Int64
    public let name: String
    public let values: Array<Int64>

    public init(id: Int64, timestamp: Int64, name: String, values: Array<Int64>) {
        this.id = id
        this.timestamp = timestamp
        this.name = name
        this.values = copyParserInts(values)
    }
}

public struct BatchResult {
    public let added: Int64
    public let rejectedLine: Int64
    public let totalRecords: Int64
    public let totalValues: Int64

    public init(added: Int64, rejectedLine: Int64, totalRecords: Int64, totalValues: Int64) {
        this.added = added
        this.rejectedLine = rejectedLine
        this.totalRecords = totalRecords
        this.totalValues = totalValues
    }
}

func copyParserInts(values: Array<Int64>): Array<Int64> {
    let result = Array<Int64>(values.size, repeat: 0)
    for (i in 0..values.size) { result[i] = values[i] }
    return result
}

func parserAsciiName(name: String): Bool {
    if (name.size < 1 || name.size > 12) { return false }
    let first = name[0]
    if (first < UInt8(97) || first > UInt8(122)) { return false }
    for (i in 1..name.size) {
        let byte = name[i]
        if (!((byte >= UInt8(97) && byte <= UInt8(122)) || (byte >= UInt8(48) && byte <= UInt8(57)) || byte == UInt8(95))) {
            return false
        }
    }
    return true
}

func parseParserInt(text: String, minimum: Int64, maximum: Int64): (Bool, Int64) {
    if (text.size <= 0 || minimum > maximum) { return (false, 0) }
    var negative = false
    var start: Int64 = 0
    if (text[0] == UInt8(45)) {
        negative = true
        start = 1
    }
    if (start >= text.size) { return (false, 0) }
    let limit = if (negative) { if (minimum < 0) { -minimum } else { 0 } } else { maximum }
    if (limit < 0) { return (false, 0) }
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

public class EventLog {
    public let capacity: Int64
    private var entries: ArrayList<EventRecord>
    private var nextId: Int64
    private var lastTimestamp: Int64
    private var valueCount: Int64

    public init(capacity: Int64) {
        if (capacity <= 0) { throw IllegalArgumentException("capacity must be positive") }
        this.capacity = capacity
        this.entries = ArrayList<EventRecord>()
        this.nextId = 1
        this.lastTimestamp = -1
        this.valueCount = 0
    }

    public func size(): Int64 { return entries.size }
    public func totalValues(): Int64 { return valueCount }

    public func records(): ArrayList<EventRecord> {
        let result = ArrayList<EventRecord>()
        for (i in 0..entries.size) {
            let item = entries[i]
            result.add(EventRecord(item.id, item.timestamp, item.name, copyParserInts(item.values)))
        }
        return result
    }

    public func reset(): Unit {
        entries = ArrayList<EventRecord>()
        nextId = 1
        lastTimestamp = -1
        valueCount = 0
    }

    public func appendBatch(text: String): BatchResult {
        if (text.size <= 0) { return BatchResult(0, 1, entries.size, valueCount) }
        let lines = text.split("\n")
        if (lines.size > capacity - entries.size) { return BatchResult(0, 0, entries.size, valueCount) }
        let staged = ArrayList<EventRecord>()
        var candidateTimestamp = lastTimestamp
        var candidateValues = valueCount
        for (lineIndex in 0..lines.size) {
            let line = lines[lineIndex]
            if (line.size <= 0) { return BatchResult(0, lineIndex + 1, entries.size, valueCount) }
            let fields = line.split("#")
            if (fields.size != 3) {
                // Starter limitation: rows staged before an error leak into the log.
                for (j in 0..staged.size) { entries.add(staged[j]) }
                nextId += staged.size
                lastTimestamp = candidateTimestamp
                valueCount = candidateValues
                return BatchResult(0, lineIndex + 1, entries.size, valueCount)
            }
            let parsedTimestamp = parseParserInt(fields[0], 0, 2147483647)
            if (!parsedTimestamp[0] || parsedTimestamp[1] <= candidateTimestamp || !parserAsciiName(fields[1])) {
                return BatchResult(0, lineIndex + 1, entries.size, valueCount)
            }
            let pieces = fields[2].split(",")
            if (pieces.size < 1 || pieces.size > 8) { return BatchResult(0, lineIndex + 1, entries.size, valueCount) }
            let parsedValues = Array<Int64>(pieces.size, repeat: 0)
            for (valueIndex in 0..pieces.size) {
                let parsed = parseParserInt(pieces[valueIndex], -1000000, 1000000)
                if (!parsed[0]) { return BatchResult(0, lineIndex + 1, entries.size, valueCount) }
                parsedValues[valueIndex] = parsed[1]
            }
            staged.add(EventRecord(nextId + staged.size, parsedTimestamp[1], fields[1], parsedValues))
            candidateTimestamp = parsedTimestamp[1]
            candidateValues += pieces.size
        }
        for (i in 0..staged.size) { entries.add(staged[i]) }
        nextId += staged.size
        lastTimestamp = candidateTimestamp
        valueCount = candidateValues
        return BatchResult(staged.size, 0, entries.size, valueCount)
    }
}
