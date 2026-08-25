package task_08_matrix_vector

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class MatrixVectorTests {
    @TestCase
    func multipliesDifferentShapes(): Unit {
        @Assert(matrixVector([1.0, 2.0, 3.0, 4.0], 2, 2, [5.0, 6.0]), [17.0, 39.0])
        @Assert(matrixVector([1.0, 0.0, -1.0, 2.0, 3.0, 4.0], 2, 3, [2.0, 1.0, 3.0]), [-1.0, 19.0])
    }
}
