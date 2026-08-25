package task_06_safe_divide

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class SafeDivideTests {
    @TestCase
    func returnsSomeOrNone(): Unit {
        @Assert(safeDivide(10.0, 2.0).getOrThrow(), 5.0)
        @Assert(safeDivide(-9.0, 3.0).getOrThrow(), -3.0)
        @Assert(safeDivide(1.0, 0.0).isNone(), true)
    }
}
