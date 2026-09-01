package ml_state_template

import std.fs.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
public class MlStateTemplateTests {
    @TestCase
    func replacesAndReadsUtf8State(): Unit {
        let path = "ml-state-template.tmp"
        removeIfExists(path)
        writeUtf8Replacing(path, "CJSTATE1\ncount=2\n")
        writeUtf8Replacing(path, "CJSTATE1\ncount=1\n")
        let content = readUtf8(path)
        @Assert(content, "CJSTATE1\ncount=1\n")
        @Assert(splitStateLines(content)[1], "count=1")
        @Assert(parseFiniteFloat64("-3.5"), -3.5)
        removeIfExists(path)
    }

    @TestCase
    func joinsPrivateWorkerResultsDeterministically(): Unit {
        @Assert(parallelScale([1.0, -2.0, 3.5], 2.0), [2.0, -4.0, 7.0])
    }

    @TestCase
    func validatesSerializedShapeAndTaggedIntegerWithoutGuessedApis(): Unit {
        @Assert(positiveDimensionsMatchLength(2, 3, 6), true)
        @Assert(positiveDimensionsMatchLength(2, 3, 5), false)
        @Assert(positiveDimensionsMatchLength(Int64.Max, 2, 6), false)
        @Assert(parseTaggedInt64("count=18", "count"), 18)
        @Assert(int64UpperBound(), Int64.Max)

        var rejected = false
        try {
            let ignored = parseTaggedInt64("count=", "count")
        } catch (_: IllegalArgumentException) {
            rejected = true
        }
        @Assert(rejected, true)
    }
}
