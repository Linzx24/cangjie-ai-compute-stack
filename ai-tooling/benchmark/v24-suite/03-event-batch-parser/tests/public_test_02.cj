package event_batch_parser

main() {
    let log = EventLog(4)
    let result = log.appendBatch("20#beta#1,-2,300\n30#gamma#7,8")
    if (result.added != 2 || result.totalRecords != 2 || result.totalValues != 5) { throw Exception("event variable batch mismatch") }
    let records = log.records()
    if (records[0].id != 1 || records[0].values.size != 3 || records[0].values[1] != -2 || records[1].id != 2 || records[1].values.size != 2) {
        throw Exception("event variable records mismatch")
    }
}
