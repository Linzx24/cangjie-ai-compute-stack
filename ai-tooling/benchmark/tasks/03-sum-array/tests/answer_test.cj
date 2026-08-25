package task_03_sum_array

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class SumArrayTests {
    @TestCase
    func sumsSeveralShapesOfInput(): Unit {
        @Assert(sumArray([1, 2, 3, 4]), 10)
        @Assert(sumArray([-2, 5, -1]), 2)
        @Assert(sumArray([0]), 0)
    }
}
