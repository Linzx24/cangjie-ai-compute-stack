package tensor_checkpoint

import std.collection.*

main() {
    let tensors = ArrayList<TensorRecord>()
    tensors.add(TensorRecord("alpha", 1, 2, [1.5, -2.0]))
    let store = TensorCheckpointStore(7, tensors)
    if (store.encode() != "CJTENSOR|1|7|1\nalpha|1|2|1.500000,-2.000000") {
        throw Exception("checkpoint canonical encoding mismatch")
    }
}
