package tensor_checkpoint

import std.collection.*

main() {
    let tensors = ArrayList<TensorRecord>()
    tensors.add(TensorRecord("keep", 1, 1, [5.0]))
    let store = TensorCheckpointStore(3, tensors)
    let before = store.encode()
    var rejected = false
    try {
        store.restore("CJTENSOR|1|99|2\nalpha|1|1|1.0\nbeta|2|2|2.0")
    } catch (e: IllegalArgumentException) {
        rejected = true
    }
    if (!rejected || store.encode() != before || store.snapshot().step != 3) {
        throw Exception("failed checkpoint restore changed state")
    }
}
