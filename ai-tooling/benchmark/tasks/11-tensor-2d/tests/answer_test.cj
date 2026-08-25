package task_11_tensor_2d

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class Tensor2DTests {
    @TestCase
    func copiesAndIndexesData(): Unit {
        let input = [1.0, 2.0, 3.0, 4.0]
        let tensor = Tensor2D(input, 2, 2)
        input[0] = 99.0
        @Assert(tensor.at(0, 0), 1.0)
        @Assert(tensor.at(1, 1), 4.0)
        let output = tensor.toArray()
        output[1] = 88.0
        @Assert(tensor.at(0, 1), 2.0)
    }

    @TestCase
    func addsReluAndSums(): Unit {
        let left = Tensor2D([-1.0, 2.0, 3.0, -4.0], 2, 2)
        let right = Tensor2D([2.0, 3.0, -3.0, 5.0], 2, 2)
        @Assert(left.add(right).toArray(), [1.0, 5.0, 0.0, 1.0])
        @Assert(left.relu().toArray(), [0.0, 2.0, 3.0, 0.0])
        @Assert(left.sum(), 0.0)
    }

    @TestCase
    func multipliesRectangularMatrices(): Unit {
        let left = Tensor2D([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 2, 3)
        let right = Tensor2D([7.0, 8.0, 9.0, 10.0, 11.0, 12.0], 3, 2)
        let result = left.matmul(right)
        @Assert(result.rows, 2)
        @Assert(result.columns, 2)
        @Assert(result.toArray(), [58.0, 64.0, 139.0, 154.0])
    }
}
