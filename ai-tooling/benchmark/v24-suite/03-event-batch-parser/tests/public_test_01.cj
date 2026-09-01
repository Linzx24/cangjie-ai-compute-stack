package event_batch_parser

main() {
    let log = EventLog(4)
    let result = log.appendBatch("10#alpha#3")
    if (result.added != 1 || result.rejectedLine != 0 || result.totalRecords != 1 || result.totalValues != 1) {
        throw Exception("event basic append mismatch")
    }
    let records = log.records()
    if (records.size != 1 || records[0].id != 1 || records[0].timestamp != 10 || records[0].name != "alpha" || records[0].values[0] != 3) {
        throw Exception("event record mismatch")
    }
    records[0].values[0] = 99
    if (log.records()[0].values[0] != 3) { throw Exception("event snapshot aliases state") }
}
