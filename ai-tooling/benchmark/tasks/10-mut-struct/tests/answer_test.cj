package task_10_mut_struct

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class MutableVectorTests {
    @TestCase
    func mutatesAndCalculatesMagnitude(): Unit {
        var vector = MutableVector2(1.5, -2.0)
        vector.scale(2.0)
        @Assert(vector.x, 3.0)
        @Assert(vector.y, -4.0)
        @Assert(vector.magnitudeSquared(), 25.0)
    }
}
