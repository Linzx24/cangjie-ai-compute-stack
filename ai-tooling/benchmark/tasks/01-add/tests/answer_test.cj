package task_01_add

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class AddTests {
    @TestCase
    func handlesPositiveAndNegativeValues(): Unit {
        @Assert(add(2, 3), 5)
        @Assert(add(-4, 1), -3)
        @Assert(add(0, 0), 0)
    }
}
