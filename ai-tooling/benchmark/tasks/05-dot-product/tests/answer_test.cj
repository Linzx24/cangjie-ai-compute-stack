package task_05_dot_product

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class DotProductTests {
    @TestCase
    func calculatesDotProducts(): Unit {
        @Assert(dotProduct([1, 2, 3], [4, 5, 6]), 32)
        @Assert(dotProduct([-1, 2], [3, 4]), 5)
        @Assert(dotProduct([0, 0], [9, -3]), 0)
    }
}
