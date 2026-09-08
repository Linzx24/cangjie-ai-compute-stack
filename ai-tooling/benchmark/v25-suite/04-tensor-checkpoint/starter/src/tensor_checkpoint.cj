package tensor_checkpoint

import std.collection.*
import std.convert.*

public struct TensorRecord {
    public let name: String
    public let rows: Int64
    public let columns: Int64
    public let values: Array<Float64>

    public init(name: String, rows: Int64, columns: Int64, values: Array<Float64>) {
        this.name = name
        this.rows = rows
        this.columns = columns
        // Incomplete starter ownership boundary.
        this.values = values
    }
}

public struct CheckpointView {
    public let step: Int64
    public let tensors: ArrayList<TensorRecord>

    public init(step: Int64, tensors: ArrayList<TensorRecord>) {
        this.step = step
        this.tensors = copyCheckpointRecords(tensors)
    }
}

func copyCheckpointFloats(values: Array<Float64>): Array<Float64> {
    let result = Array<Float64>(values.size, repeat: 0.0)
    for (i in 0..values.size) { result[i] = values[i] }
    return result
}

func copyCheckpointRecords(values: ArrayList<TensorRecord>): ArrayList<TensorRecord> {
    let result = ArrayList<TensorRecord>()
    for (i in 0..values.size) {
        let item = values[i]
        result.add(TensorRecord(item.name, item.rows, item.columns, item.values))
    }
    return result
}

func checkpointFinite(value: Float64): Bool {
    return !value.isNaN() && !value.isInf()
}

func checkpointNameValid(name: String): Bool {
    if (name.size < 1 || name.size > 16) { return false }
    if (name[0] < UInt8(97) || name[0] > UInt8(122)) { return false }
    for (i in 1..name.size) {
        let byte = name[i]
        if (!((byte >= UInt8(97) && byte <= UInt8(122)) || (byte >= UInt8(48) && byte <= UInt8(57)) || byte == UInt8(95))) { return false }
    }
    return true
}

func checkpointNameBefore(left: String, right: String): Bool {
    let common = if (left.size < right.size) { left.size } else { right.size }
    for (i in 0..common) {
        if (left[i] < right[i]) { return true }
        if (left[i] > right[i]) { return false }
    }
    return left.size < right.size
}

func parseCheckpointInteger(text: String, minimum: Int64, maximum: Int64): (Bool, Int64) {
    if (text.size <= 0 || minimum < 0 || minimum > maximum) { return (false, 0) }
    if (text.size > 1 && text[0] == UInt8(48)) { return (false, 0) }
    var value: Int64 = 0
    for (i in 0..text.size) {
        let byte = text[i]
        if (byte < UInt8(48) || byte > UInt8(57)) { return (false, 0) }
        let digit = Int64(byte - UInt8(48))
        if (value > (maximum - digit) / 10) { return (false, 0) }
        value = value * 10 + digit
    }
    if (value < minimum || value > maximum) { return (false, 0) }
    return (true, value)
}

func parseCheckpointFloat(text: String): (Bool, Float64) {
    if (text.size <= 0) { return (false, 0.0) }
    try {
        let value = Float64.parse(text)
        if (!checkpointFinite(value) || value.toString() != text) { return (false, 0.0) }
        return (true, value)
    } catch (e: Exception) {
        return (false, 0.0)
    }
}

func validateCheckpoint(step: Int64, tensors: ArrayList<TensorRecord>): Unit {
    if (step < 0 || step > 1000000000 || tensors.size > 16) { throw IllegalArgumentException("invalid checkpoint header state") }
    var previous = ""
    for (i in 0..tensors.size) {
        let item = tensors[i]
        if (!checkpointNameValid(item.name) || (i > 0 && !checkpointNameBefore(previous, item.name))) {
            throw IllegalArgumentException("invalid checkpoint tensor order")
        }
        if (item.rows <= 0 || item.columns <= 0 || item.values.size < 1 || item.values.size > 1024) {
            throw IllegalArgumentException("invalid checkpoint tensor shape")
        }
        if (item.values.size % item.columns != 0 || item.values.size / item.columns != item.rows) {
            throw IllegalArgumentException("checkpoint dimensions do not match values")
        }
        for (j in 0..item.values.size) {
            if (!checkpointFinite(item.values[j])) { throw IllegalArgumentException("checkpoint values must be finite") }
        }
        previous = item.name
    }
}

func encodeCheckpoint(step: Int64, tensors: ArrayList<TensorRecord>): String {
    validateCheckpoint(step, tensors)
    var text = "CJTENSOR|1|" + step.toString() + "|" + tensors.size.toString()
    for (i in 0..tensors.size) {
        let item = tensors[i]
        text += "\n" + item.name + "|" + item.rows.toString() + "|" + item.columns.toString() + "|"
        for (j in 0..item.values.size) {
            if (j > 0) { text += "," }
            text += item.values[j].toString()
        }
    }
    return text
}

func parseCheckpoint(text: String): CheckpointView {
    if (text.size <= 0) { throw IllegalArgumentException("empty checkpoint") }
    let lines = text.split("\n")
    let header = lines[0].split("|")
    if (header.size != 4 || header[0] != "CJTENSOR" || header[1] != "1") { throw IllegalArgumentException("invalid checkpoint header") }
    let step = parseCheckpointInteger(header[2], 0, 1000000000)
    let count = parseCheckpointInteger(header[3], 0, 16)
    if (!step[0] || !count[0] || lines.size != count[1] + 1) { throw IllegalArgumentException("invalid checkpoint record count") }
    let records = ArrayList<TensorRecord>()
    var previous = ""
    for (i in 0..count[1]) {
        let fields = lines[i + 1].split("|")
        if (fields.size != 4 || !checkpointNameValid(fields[0]) || (i > 0 && !checkpointNameBefore(previous, fields[0]))) {
            throw IllegalArgumentException("invalid checkpoint record")
        }
        let rows = parseCheckpointInteger(fields[1], 1, Int64.Max)
        let columns = parseCheckpointInteger(fields[2], 1, Int64.Max)
        let pieces = fields[3].split(",")
        if (!rows[0] || !columns[0] || pieces.size < 1 || pieces.size > 1024 || pieces.size % columns[1] != 0 || pieces.size / columns[1] != rows[1]) {
            throw IllegalArgumentException("invalid checkpoint dimensions")
        }
        let values = Array<Float64>(pieces.size, repeat: 0.0)
        for (j in 0..pieces.size) {
            let parsed = parseCheckpointFloat(pieces[j])
            if (!parsed[0]) { throw IllegalArgumentException("invalid checkpoint value") }
            values[j] = parsed[1]
        }
        records.add(TensorRecord(fields[0], rows[1], columns[1], values))
        previous = fields[0]
    }
    validateCheckpoint(step[1], records)
    return CheckpointView(step[1], records)
}

public class TensorCheckpointStore {
    private var stepState: Int64
    private var tensorState: ArrayList<TensorRecord>

    public init(step: Int64, tensors: ArrayList<TensorRecord>) {
        validateCheckpoint(step, tensors)
        this.stepState = step
        this.tensorState = copyCheckpointRecords(tensors)
    }

    public func snapshot(): CheckpointView { return CheckpointView(stepState, tensorState) }
    public func encode(): String { return encodeCheckpoint(stepState, tensorState) }

    public func restore(text: String): Unit {
        // Incomplete starter restore transition.
        let lines = text.split("\n")
        if (lines.size > 0) {
            let header = lines[0].split("|")
            if (header.size == 4 && header[0] == "CJTENSOR" && header[1] == "1") {
                let parsedStep = parseCheckpointInteger(header[2], 0, 1000000000)
                if (parsedStep[0]) { stepState = parsedStep[1] }
            }
        }
        let candidate = parseCheckpoint(text)
        stepState = candidate.step
        tensorState = copyCheckpointRecords(candidate.tensors)
    }
}
