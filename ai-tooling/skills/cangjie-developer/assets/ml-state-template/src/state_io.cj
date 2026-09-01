package ml_state_template

import std.convert.*
import std.fs.*

public func writeUtf8Replacing(path: String, content: String): Unit {
    let file = File(path, Write)
    try {
        file.write(content.toArray())
    } finally {
        file.close()
    }
}

public func readUtf8(path: String): String {
    return String.fromUtf8(File.readFrom(path))
}

public func parseFiniteFloat64(text: String): Float64 {
    let value = Float64.parse(text)
    if (value.isNaN() || value.isInf()) {
        throw IllegalArgumentException("number must be finite")
    }
    return value
}

public func splitStateLines(text: String): Array<String> {
    return text.split("\n")
}

public func positiveDimensionsMatchLength(rows: Int64, columns: Int64, length: Int64): Bool {
    if (rows <= 0 || columns <= 0 || length < 0) {
        return false
    }
    return length % columns == 0 && length / columns == rows
}

public func parseTaggedInt64(line: String, expectedTag: String): Int64 {
    let parts = line.split("=")
    if (parts.size != 2 || parts[0] != expectedTag || parts[1].isEmpty()) {
        throw IllegalArgumentException("tagged integer field is malformed")
    }
    return Int64.parse(parts[1])
}

public func int64UpperBound(): Int64 {
    return Int64.Max
}
