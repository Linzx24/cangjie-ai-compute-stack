package cjtensor

/**
 * Trains y = weight * x + bias on four exact points using Value autograd.
 * Returns the learned weight, bias, and final sum-of-squares loss.
 */
public func trainLinearRegression(epochs!: Int64 = 200, learningRate!: Float64 = 0.05): (Float64, Float64, Float64) {
    if (epochs <= 0) {
        throw IllegalArgumentException("epochs must be positive.")
    }
    if (learningRate <= 0.0) {
        throw IllegalArgumentException("learningRate must be positive.")
    }

    let inputs = [-1.0, 0.0, 1.0, 2.0]
    let targets = [-1.0, 1.0, 3.0, 5.0]
    let weight = Value(0.0)
    let bias = Value(0.0)

    for (_ in 0..epochs) {
        weight.zeroGrad()
        bias.zeroGrad()

        for (index in 0..inputs.size) {
            let input = Value(inputs[index])
            let negativeTarget = Value(-targets[index])
            let prediction = weight.multiply(input).add(bias)
            let error = prediction.add(negativeTarget)
            let squaredError = error.multiply(error)
            squaredError.backward()
        }

        weight.data -= learningRate * weight.grad
        bias.data -= learningRate * bias.grad
    }

    var finalLoss: Float64 = 0.0
    for (index in 0..inputs.size) {
        let error = weight.data * inputs[index] + bias.data - targets[index]
        finalLoss += error * error
    }
    return (weight.data, bias.data, finalLoss)
}
