---
name: project-pipeline-design
description: Agreed pipeline architecture for clavr2 multi-ISA framework — no microcode in Core, dynamic ISA typeclass
metadata:
  type: project
---

No microcode in Core this round. Each ISA is dynamic and implements the ISA typeclass directly.

**Why:** Microcode was considered and rejected — it fixes a µop set in Core and constrains ISA implementations. Instead, one of the ISA implementations can itself be a microcode translator if needed for complex ISAs (e.g. x86-like). Core stays agnostic.

**Agreed design direction:**
- `Core.ISA` — typeclass with associated types; exposes only the qualities that drive pipeline decisions
- `Core.Pipeline` — generic N-deep pipeline (`Vec n (Slot isa)`), generic over any `ISA` instance
- `Core.Flush` — first-class `FlushEvent` type; `HasFlush` typeclass separates detection from application; flush is independently testable
- Pipeline depth `n` is a compile-time `Nat` tuning knob (n=1 = fully serial)
- `latency :: Instr isa -> Int` quality handles multi-cycle ops like MUL via NOP insertion
- `toIsaStage` / `IsaStage` escape hatch handles structurally complex multi-cycle ops (CALL/RET/LPM)
- ISA qualities: isaRead, isaCompute, isaWrite, isaJump, interruptible, acceptIrq, latency, toIsaStage

**How to apply:** When implementing Core.ISA, Core.Pipeline, Core.Flush — do not introduce a fixed µop set or microcode sequencer in Core. Keep pipeline decision logic driven purely by ISA typeclass methods.
