package task_04_factorial

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class FactorialTests {
    @TestCase
    func handlesBaseAndRecursiveCases(): Unit {
        @Assert(factorial(0), 1)
        @Assert(factorial(1), 1)
        @Assert(factorial(5), 120)
        @Assert(factorial(10), 3628800)
    }
}
