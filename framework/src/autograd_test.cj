package cjtensor

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class AutogradTests {
    @TestCase
    func differentiatesSharedInputGraph(): Unit {
        let x = Value(3.0)
        let y = x.multiply(x).add(x)

        y.backward()

        @Assert(y.data, 12.0)
        @Assert(y.grad, 1.0)
        @Assert(x.grad, 7.0)
    }

    @TestCase
    func agreesWithNumericalGradient(): Unit {
        let input = 1.7
        let epsilon = 0.000001
        let x = Value(input)
        let y = x.multiply(x).add(x)
        y.backward()

        let upper = (input + epsilon) * (input + epsilon) + (input + epsilon)
        let lower = (input - epsilon) * (input - epsilon) + (input - epsilon)
        let numericalGradient = (upper - lower) / (2.0 * epsilon)
        let difference = if (x.grad > numericalGradient) {
            x.grad - numericalGradient
        } else {
            numericalGradient - x.grad
        }

        @Assert(difference < 0.000001)
    }

    @TestCase
    func trainsLinearRegressionEndToEnd(): Unit {
        let result = trainLinearRegression()
        let weightError = if (result[0] > 2.0) { result[0] - 2.0 } else { 2.0 - result[0] }
        let biasError = if (result[1] > 1.0) { result[1] - 1.0 } else { 1.0 - result[1] }

        @Assert(weightError < 0.0001)
        @Assert(biasError < 0.0001)
        @Assert(result[2] < 0.000001)
    }

    @TestCase
    func rejectsInvalidTrainingConfiguration(): Unit {
        @AssertThrows[IllegalArgumentException](trainLinearRegression(epochs: 0))
        @AssertThrows[IllegalArgumentException](trainLinearRegression(learningRate: 0.0))
    }
}
