# Deterministic beam frontier

Implement starter/src/beam_frontier.cj for Cangjie 1.1.3 using only the
standard library. Keep every public declaration and do not add a main
function. The checked-in starter intentionally includes a local collection
API mistake as well as an incomplete expansion loop; use compiler diagnostics
and the contract below to repair the complete source.

The API is:

    BeamChoice(parent: Int64, token: Int64, score: Float64)
    BeamStep(choices: ArrayList<BeamChoice>, step: Int64)
    BeamFrontier(
        initialScores: Array<Float64>, vocabulary: Int64, beamWidth: Int64
    )
    scores(): Array<Float64>
    step(): Int64
    expand(tokenLogProbabilities: Array<Float64>): BeamStep
    reset(): Unit

initialScores is non-empty, finite, and has at most beamWidth entries.
vocabulary and beamWidth are positive. The constructor owns initialScores and
scores returns an independent snapshot.

On expand, let currentCount be the current number of scores. The input is a
row-major currentCount by vocabulary array. Candidate (parent, token) has
score currentScore[parent] + tokenLogProbabilities[parent*vocabulary+token].
Validate the shape product before multiplying and require every input and
candidate score to be finite.

Select min(beamWidth, currentCount*vocabulary) distinct candidates. Sort by
descending score; ties choose the smaller parent and then the smaller token.
The returned choices follow exactly that order. Their scores become the next
frontier in the same order, and step advances once.

An invalid expansion must preserve scores and step. BeamStep owns an
independent list. reset restores the original scores and step zero.
