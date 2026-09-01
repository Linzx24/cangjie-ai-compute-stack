package softmax_trainer

main() {
    let trainer = SoftmaxTrainer(2, 2, 0.1)
    _ = trainer.trainBatch([1.0, 0.0], [1])
    let beforeWeights = trainer.weights()
    let beforeBias = trainer.bias()
    let beforeStep = trainer.step()
    var rejectedShape = false
    try {
        _ = trainer.trainBatch([1.0], [0])
    } catch (e: Exception) {
        rejectedShape = true
    }
    var rejectedLabel = false
    try {
        _ = trainer.trainBatch([1.0, 0.0], [9])
    } catch (e: Exception) {
        rejectedLabel = true
    }
    if (!rejectedShape || !rejectedLabel || trainer.step() != beforeStep) { throw Exception("trainer rejected update state changed") }
    let afterWeights = trainer.weights()
    let afterBias = trainer.bias()
    for (i in 0..beforeWeights.size) {
        if (afterWeights[i] != beforeWeights[i]) { throw Exception("trainer weights changed on rejection") }
    }
    for (i in 0..beforeBias.size) {
        if (afterBias[i] != beforeBias[i]) { throw Exception("trainer bias changed on rejection") }
    }
}
