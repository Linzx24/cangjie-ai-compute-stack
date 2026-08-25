package task_09_generic_swap

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class GenericSwapTests {
    @TestCase
    func swapsMultipleTypes(): Unit {
        let integers = swap<Int64>((1, 2))
        @Assert(integers[0], 2)
        @Assert(integers[1], 1)
        let strings = swap<String>(("left", "right"))
        @Assert(strings[0], "right")
        @Assert(strings[1], "left")
    }
}
