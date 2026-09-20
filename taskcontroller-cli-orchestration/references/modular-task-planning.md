# Modular task planning

## Principles learned from the noise-removal example

An executor is a field on an execution task, not part of its name. For example, use `ImplementMovingAverageCore` with `Executor: Hourai`, not `Hourai-ImplementMovingAverageCore`.

The tree describes decomposition; relations describe prerequisite order. Use both:

```text
NoiseRemovalAlgorithm
├─ SpecificationModule                 (no executor)
│  ├─ DefineInputOutputContract         (Shanghai)
│  ├─ CreateNoisyTestFixtures           (Kyoto)
│  └─ SelectMovingAverageParameters     (Shanghai)
├─ ImplementationModule                 (no executor)
│  └─ MovingAverageCoreModule           (no executor)
│     ├─ ImplementWindowAccumulation     (Hourai)
│     ├─ ImplementNormalization          (Hourai)
│     └─ HandleBoundaryAndInvalidSamples (Hourai)
├─ QualityModule                        (no executor)
└─ DeliveryModule                       (no executor)
```

In the example, the two specification leaves may start together. Parameter selection depends on both. The implementation leaves depend on the approved parameters; tests and quality measurement depend on the correct implementation. Encode only genuine prerequisites so independent work remains schedulable.

## Granularity test

Create a child subtree when a proposed task contains multiple independently reviewable steps, multiple deliverables, or a handoff between roles. A leaf should state one observable outcome and answer all of these:

- What artifact or behavior is produced?
- Who owns it (`Executor`)?
- What exact prerequisites are required?
- How will it be verified?

Module and integration nodes generally have an empty executor. Assign an executor only to leaves that someone can actually start and finish. A parent may be left unassigned even when all of its child leaves share the same owner.

## Scheduling lifecycle

Use `plan --strategy clever --count <N> --write` to mark only currently unblocked work as active. When a leaf finishes, run `task set-status <name> Done --write`, validate, then run `plan` again. Do not mark a task `Done` merely to force-open a blocked successor.
