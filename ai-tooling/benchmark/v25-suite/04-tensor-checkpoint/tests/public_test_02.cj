package tensor_checkpoint

import std.collection.*

main() {
    let tensors = ArrayList<TensorRecord>()
    let store = TensorCheckpointStore(0, tensors)
    let text = "CJTENSOR|1|12|2\nalpha|1|1|3.000000\nbeta_2|2|2|1.000000,2.000000,3.000000,4.000000"
    store.restore(text)
    let snapshot = store.snapshot()
    if (snapshot.step != 12 || snapshot.tensors.size != 2 || snapshot.tensors[1].rows != 2 || snapshot.tensors[1].values[3] != 4.0) {
        throw Exception("checkpoint restore mismatch")
    }
    if (store.encode() != text) { throw Exception("checkpoint round trip is not canonical") }
}
