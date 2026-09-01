package softmax_trainer

func trainerNear2(actual: Float64, expected: Float64): Unit {
    var difference = actual - expected
    if (difference < 0.0) { difference = -difference }
    if (difference > 1.0e-9) { throw Exception("trainer batch mismatch") }
}

main() {
    let trainer = SoftmaxTrainer(2, 2, 0.5)
    let first = trainer.trainBatch([1.0, 0.0, 0.0, 1.0], [0, 1])
    if (first.step != 1 || first.accuracy != 0.5) { throw Exception("trainer first batch report mismatch") }
    let weights = trainer.weights()
    trainerNear2(weights[0], 0.125)
    trainerNear2(weights[1], -0.125)
    trainerNear2(weights[2], -0.125)
    trainerNear2(weights[3], 0.125)
    let prediction = trainer.predict([1.0, 0.0, 0.0, 1.0])
    if (prediction[0] != 0 || prediction[1] != 1) { throw Exception("trainer prediction mismatch") }
    let second = trainer.trainBatch([1.0, 0.0, 0.0, 1.0], [0, 1])
    if (second.step != 2 || second.accuracy < 0.99) { throw Exception("trainer second batch state mismatch") }
}
