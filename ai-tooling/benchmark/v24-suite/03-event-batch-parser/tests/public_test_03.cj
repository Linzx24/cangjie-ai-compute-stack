package event_batch_parser

main() {
    let log = EventLog(4)
    _ = log.appendBatch("10#alpha#1")
    let result = log.appendBatch("20#beta#2\nnot-an-event")
    if (result.added != 0 || result.rejectedLine != 2 || result.totalRecords != 1 || log.size() != 1) {
        throw Exception("event batch was not atomic")
    }
    if (log.records()[0].id != 1 || log.records()[0].timestamp != 10) { throw Exception("event rollback changed committed row") }
    let next = log.appendBatch("30#gamma#4")
    if (next.added != 1 || log.records()[1].id != 2) { throw Exception("event rollback consumed id") }
}
