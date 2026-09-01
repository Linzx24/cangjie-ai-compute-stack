# Stateful minibatch softmax trainer

Implement `starter/src/softmax_trainer.cj` as a dependency-free Cangjie
1.1.3 CPU component. The evaluator replaces only that source file and
compiles each public test separately. Keep all declarations below public and
do not add a `main` function.

The public API is `BatchReport`, `SoftmaxTrainer`, and these methods:

```text
BatchReport(loss: Float64, accuracy: Float64, step: Int64, applied: Bool)
SoftmaxTrainer(featureCount: Int64, classCount: Int64, learningRate: Float64)
weights(): Array<Float64>
bias(): Array<Float64>
step(): Int64
reset(): Unit
predict(features: Array<Float64>): Array<Int64>
trainBatch(features: Array<Float64>, labels: Array<Int64>): BatchReport
```

The constructor requires `featureCount > 0`, `classCount > 1`, and a finite
strictly positive learning rate. Parameters start at zero and are laid out as
`weights[feature*classCount + class]`; bias has one value per class. Every
array returned by an accessor is an independent snapshot.

`features` is a non-empty row-major batch with
`features.size == batchSize * featureCount`. Labels has exactly one value per
row and each label is in `0..classCount-1`. Reject bad shapes, labels, NaN,
or infinity before changing any state. A failed call must leave weights,
bias, and step unchanged.

For each row compute logits `bias + features @ weights`, subtract the row
maximum before exponentiating, and form a stable softmax. The reported loss
is the mean negative log probability of the label, and accuracy is the mean
pre-update argmax accuracy with ties choosing the smallest class. Compute the
mean gradients for weights and bias, then apply one SGD update using the
configured learning rate. Validate all candidate values before committing the
arrays and incrementing `step` exactly once. Set `applied` to true on a
successful update. `reset` restores zero parameters and step zero.
