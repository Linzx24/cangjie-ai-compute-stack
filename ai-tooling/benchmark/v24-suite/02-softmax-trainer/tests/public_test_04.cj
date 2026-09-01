package softmax_trainer

main() {
    let trainer = SoftmaxTrainer(1, 2, 0.3)
    _ = trainer.trainBatch([2.0], [1])
    let snapshot = trainer.weights()
    snapshot[0] = 777.0
    if (trainer.weights()[0] == 777.0) { throw Exception("trainer accessor aliases state") }
    trainer.reset()
    if (trainer.step() != 0) { throw Exception("trainer reset step mismatch") }
    let weights = trainer.weights()
    let bias = trainer.bias()
    for (i in 0..weights.size) {
        if (weights[i] != 0.0) { throw Exception("trainer reset weights mismatch") }
    }
    for (i in 0..bias.size) {
        if (bias[i] != 0.0) { throw Exception("trainer reset bias mismatch") }
    }
}
