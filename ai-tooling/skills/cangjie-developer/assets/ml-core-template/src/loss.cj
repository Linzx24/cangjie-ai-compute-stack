package ml_core_template

public func meanSquaredErrorAndGradient(predictions: Array<Float64>, targets: Array<Float64>): (Float64, Array<Float64>) {
    if (predictions.size == 0 || predictions.size != targets.size) {
        throw IllegalArgumentException("invalid loss inputs")
    }
    for (value in predictions) {
        if (!templateFinite(value)) {
            throw IllegalArgumentException("predictions must be finite")
        }
    }
    for (value in targets) {
        if (!templateFinite(value)) {
            throw IllegalArgumentException("targets must be finite")
        }
    }
    let gradient = Array<Float64>(predictions.size, repeat: 0.0)
    var loss = 0.0
    let count = Float64(predictions.size)
    for (index in 0..predictions.size) {
        let error = predictions[index] - targets[index]
        if (!templateFinite(error)) {
            throw IllegalArgumentException("loss error is not finite")
        }
        loss += error * error
        gradient[index] = 2.0 * error / count
        if (!templateFinite(gradient[index])) {
            throw IllegalArgumentException("loss gradient is not finite")
        }
    }
    let meanLoss = loss / count
    if (!templateFinite(meanLoss)) {
        throw IllegalArgumentException("loss is not finite")
    }
    return (meanLoss, gradient)
}
