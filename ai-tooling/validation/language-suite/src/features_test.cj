package cangjie_language_suite

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class LanguageFeatureTests {
    @TestCase
    func supportsLambdaAndFunctionTypes(): Unit {
        let increment: (Int64) -> Int64 = {value => value + 1}
        @Assert(applyTwice(3, increment), 5)
    }

    @TestCase
    func distinguishesStructAndClassMutation(): Unit {
        var counter = Counter(4)
        counter.increment()
        @Assert(counter.value, 5)
        @Assert(Scale(2.5).apply(4.0), 10.0)
    }

    @TestCase
    func supportsGenericsAndExhaustiveOptionMatching(): Unit {
        @Assert(identity<String>("cangjie"), "cangjie")
        @Assert(valueOr(Some(8), 0), 8)
        @Assert(valueOr(None, 7), 7)
    }

    @TestCase
    func usesArraysInterfacesAndCollections(): Unit {
        @Assert(scaledCopy([1.0, -2.0], Scale(3.0)), [3.0, -6.0])
        let collected = collectNonNegative([-1, 0, 2])
        @Assert(collected.size, 2)
        @Assert(collected[0], 0)
        @Assert(collected[1], 2)
    }

    @TestCase
    func preservesExceptionContracts(): Unit {
        var caught = false
        try {
            requireNonNegative(-1)
        } catch (_: IllegalArgumentException) {
            caught = true
        }
        @Assert(caught, true)
        @Assert(requireNonNegative(3), 3)
    }
}
