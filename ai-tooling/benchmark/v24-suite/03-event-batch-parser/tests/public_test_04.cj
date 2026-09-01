package event_batch_parser

main() {
    let log = EventLog(2)
    _ = log.appendBatch("1#a#1\n2#b#2")
    let full = log.appendBatch("3#c#3")
    if (full.added != 0 || full.rejectedLine != 0 || log.size() != 2 || log.totalValues() != 2) { throw Exception("event capacity mismatch") }
    log.reset()
    if (log.size() != 0 || log.totalValues() != 0) { throw Exception("event reset mismatch") }
    let afterReset = log.appendBatch("1#z#5")
    if (afterReset.added != 1 || log.records()[0].id != 1) { throw Exception("event reset id mismatch") }
}
