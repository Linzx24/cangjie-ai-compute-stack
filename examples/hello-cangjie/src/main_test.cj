package hello_cangjie

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class AdditionTests {
    @TestCase
    func addsTwoIntegers(): Unit {
        @Assert(add(1, 2), 3)
        @Assert(add(-2, 2), 0)
    }
}
