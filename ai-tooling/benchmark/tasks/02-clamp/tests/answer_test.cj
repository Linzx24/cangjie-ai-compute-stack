package task_02_clamp

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class ClampTests {
    @TestCase
    func handlesBoundsAndMiddle(): Unit {
        @Assert(clamp(-5, 0, 10), 0)
        @Assert(clamp(15, 0, 10), 10)
        @Assert(clamp(5, 0, 10), 5)
        @Assert(clamp(0, 0, 10), 0)
        @Assert(clamp(10, 0, 10), 10)
    }
}
