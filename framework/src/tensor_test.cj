package cjtensor

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class TensorTests {
    @TestCase
    func ownsItsDataAndIndexesInRowMajorOrder(): Unit {
        let input = [1.0, 2.0, 3.0, 4.0]
        let tensor = Tensor(input, 2, 2)
        input[0] = 99.0

        @Assert(tensor.rows, 2)
        @Assert(tensor.columns, 2)
        @Assert(tensor.at(0, 0), 1.0)
        @Assert(tensor.at(1, 1), 4.0)

        let output = tensor.toArray()
        output[1] = 88.0
        @Assert(tensor.at(0, 1), 2.0)
    }

    @TestCase
    func computesElementWiseOperationsAndReduction(): Unit {
        let left = Tensor([-1.0, 2.0, 3.0, -4.0], 2, 2)
        let right = Tensor([2.0, 3.0, -3.0, 5.0], 2, 2)

        @Assert(left.add(right).toArray(), [1.0, 5.0, 0.0, 1.0])
        @Assert(left.multiply(right).toArray(), [-2.0, 6.0, -9.0, -20.0])
        @Assert(left.relu().toArray(), [0.0, 2.0, 3.0, 0.0])
        @Assert(left.sum(), 0.0)
        @Assert(Tensor.zeros(2, 3).toArray(), [0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    }

    @TestCase
    func multipliesRectangularMatrices(): Unit {
        let left = Tensor([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 2, 3)
        let right = Tensor([7.0, 8.0, 9.0, 10.0, 11.0, 12.0], 3, 2)
        let result = left.matmul(right)

        @Assert(result.rows, 2)
        @Assert(result.columns, 2)
        @Assert(result.toArray(), [58.0, 64.0, 139.0, 154.0])
    }

    @TestCase
    func rejectsInvalidShapesAndIndices(): Unit {
        @AssertThrows[IllegalArgumentException](Tensor([1.0, 2.0], 2, 2))
        @AssertThrows[IllegalArgumentException](Tensor.zeros(-1, 2))
        @AssertThrows[IndexOutOfBoundsException](Tensor([1.0], 1, 1).at(1, 0))
        @AssertThrows[IllegalArgumentException](Tensor([1.0], 1, 1).add(Tensor([1.0, 2.0], 1, 2)))
        @AssertThrows[IllegalArgumentException](Tensor([1.0, 2.0], 1, 2).matmul(Tensor([1.0], 1, 1)))
    }
}
