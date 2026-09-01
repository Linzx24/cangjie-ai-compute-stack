package ml_core_template
import std.unittest.*
import std.unittest.testmacro.*

@Test
public class MlCoreTemplateTests {
    @TestCase
    func verifiesOwnershipLossAndConcurrency(): Unit {
        let source = [1.0, 2.0, 3.0, 4.0]
        let tensor = Tensor2D(source, 2, 2)
        source[0] = 99.0
        @Assert(tensor.at(0, 0), 1.0)
        @Assert(parallelRowSums(tensor), [3.0, 7.0])
        let loss = meanSquaredErrorAndGradient([1.0, 3.0], [0.0, 1.0])
        @Assert(loss[0], 2.5)
        @Assert(loss[1], [1.0, 2.0])
    }

    @TestCase
    func rejectsNonFiniteNumericalInputs(): Unit {
        var tensorRejected = false
        try {
            let ignored = Tensor2D([Float64.NaN], 1, 1)
        } catch (_: IllegalArgumentException) {
            tensorRejected = true
        }
        @Assert(tensorRejected, true)

        var infinityTensorRejected = false
        try {
            let infinity = 1.0 / 0.0
            let ignored = Tensor2D([infinity], 1, 1)
        } catch (_: IllegalArgumentException) {
            infinityTensorRejected = true
        }
        @Assert(infinityTensorRejected, true)

        var lossRejected = false
        try {
            let ignored = meanSquaredErrorAndGradient([0.0], [Float64.NaN])
        } catch (_: IllegalArgumentException) {
            lossRejected = true
        }
        @Assert(lossRejected, true)
    }
}
