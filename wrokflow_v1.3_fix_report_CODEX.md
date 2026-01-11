# Workflow v1.3 Email Issue Report

> **UPDATE (2026-01-11):** This analysis was **INCORRECT**. The proposed fix (swapping Loop Over Items1 outputs) broke the workflow entirely - the loop stopped triggering and no Canva designs were created. The n8n SplitInBatches node outputs are: Output 0 = Done (fires once), Output 1 = Loop (fires per item). The original wiring was correct. The root cause of multiple emails remains unresolved.

## Findings
- `workflows/StarTraining Pipeline v1.3.json:560-574` — `Loop Over Items1` (SplitInBatches) has two outputs: first = per-item/batch, second = “no items left”.
- `12. Send Email` is wired to the first (per-item) output, so it fires once per batch/item (e.g., seven designs → seven emails).
- This wiring conflicts with the Gmail node note (“Sends ONE email after all designs are uploaded”); it is placed inside the loop rather than after it.

## Suggested Changes
- Rewire `12. Send Email` to the second output (“no items left”) of `Loop Over Items1` so it triggers exactly once after all items finish. Keep `Prepare a Canva Request1` on the first output for per-item processing.
- Optional clarity: add a NoOp/IF on the “no items left” branch and connect the Gmail node there to make the post-loop intent explicit in the UI.

## Why
- In n8n SplitInBatches, the first output runs per item; the second runs once when the loop completes. Moving the Gmail node to the second output aligns behavior with the goal: a single summary email with both folder links after all designs are uploaded.
