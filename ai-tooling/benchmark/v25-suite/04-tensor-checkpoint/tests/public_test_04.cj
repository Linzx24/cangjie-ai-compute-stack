package tensor_checkpoint

import std.collection.*

main() {
    let values = [2.0, 4.0]
    let tensors = ArrayList<TensorRecord>()
    tensors.add(TensorRecord("weight", 1, 2, values))
    let store = TensorCheckpointStore(1, tensors)
    values[0] = 99.0
    tensors[0].values[1] = 88.0
    if (store.snapshot().tensors[0].values[0] != 2.0 || store.snapshot().tensors[0].values[1] != 4.0) {
        throw Exception("checkpoint constructor aliases input")
    }
    let snapshot = store.snapshot()
    snapshot.tensors[0].values[0] = 77.0
    if (store.snapshot().tensors[0].values[0] != 2.0) { throw Exception("checkpoint snapshot aliases state") }
}
