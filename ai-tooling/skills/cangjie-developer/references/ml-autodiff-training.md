# Autodiff and training state

Read this reference for reverse-mode differentiation, parameters, optimizers,
and training loops. Keep graph behavior and state transitions explicit.

## Reverse-mode graph

- Build the reverse traversal from nodes reachable from the scalar loss. Visit
  nodes in reverse topological order; do not depend on construction order.
- Accumulate all incoming contributions before propagating through a node. A
  shared parent receives the sum of every branch, never the last assignment.
- For `C = A @ B`, use `dA = dC @ B^T` and `dB = A^T @ dC`. A reduction sum
  broadcasts its upstream scalar to every input element.
- Define repeated `backward` behavior. If gradients accumulate, two identical
  calls double the gradient; if they replace, clear deliberately. `zeroGrad`
  covers every registered variable, while constants never acquire gradients.
- Check a shared branch, matrix product, reduction, reset transition, and a
  constant leaf. A single finite-difference point is not enough evidence.

## Parameters and modules

- A `Parameter` owns value and gradient arrays. Accessors return independent
  snapshots unless the API explicitly promises a mutable view.
- Register each parameter once in stable order. Preserve training/evaluation
  mode and `requiresGrad` as real state; frozen parameters may participate in
  forward computation but do not receive or apply gradients.
- A row bias has one value per output column and is indexed by column. Mean
  objectives divide both reported loss and per-example gradients by batch size.

## Optimizer and training transition

1. Validate every hyperparameter, parameter, gradient, shape, and finite value.
2. Compute all candidate parameter and optimizer-state arrays in private storage.
3. Validate every candidate value.
4. Commit parameters, velocity/moments, and step counters together.

Never update parameter zero before discovering parameter one is invalid. Test
at least two successful updates and a rejected multi-parameter step, comparing
all parameters, optimizer arrays, counters, and returned snapshots before and
after rejection.

For loss-scaled updates, branch on a reported overflow before inspecting an
otherwise unusable gradient. That branch may change only the scale when the
contract says so. On the ordinary branch, unscale first, compute every momentum
and parameter candidate privately, then apply the same finite/range checks and
single commit described above. Preserve the stated floating-point operation
order and do not add decimal quantization merely to satisfy an exact comparison;
known-answer tests for non-integral results should use a justified tolerance.
