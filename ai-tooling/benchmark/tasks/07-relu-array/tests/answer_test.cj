package task_07_relu_array

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class ReluTests {
    @TestCase
    func mapsValuesWithoutChangingInput(): Unit {
        let input = [-2.0, 0.0, 3.5, -0.5]
        @Assert(relu(input), [0.0, 0.0, 3.5, 0.0])
        @Assert(input, [-2.0, 0.0, 3.5, -0.5])
    }
}
