package softmax_trainer

import std.math.*

func trainerNear(actual: Float64, expected: Float64): Unit {
    var difference = actual - expected
    if (difference < 0.0) { difference = -difference }
    if (difference > 1.0e-9) { throw Exception("trainer known answer mismatch") }
}

main() {
    let trainer = SoftmaxTrainer(2, 2, 0.2)
    let report = trainer.trainBatch([1.0, 0.0], [1])
    if (!report.applied || report.step != 1 || report.accuracy != 0.0) { throw Exception("trainer report mismatch") }
    trainerNear(report.loss, log(2.0))
    let weights = trainer.weights()
    let bias = trainer.bias()
    trainerNear(weights[0], -0.1)
    trainerNear(weights[1], 0.1)
    trainerNear(weights[2], 0.0)
    trainerNear(weights[3], 0.0)
    trainerNear(bias[0], -0.1)
    trainerNear(bias[1], 0.1)
}
