# Workflow v1.3 Email Bug Analysis and Fix Proposal

> **UPDATE (2026-01-11):** This analysis was **INCORRECT**. The proposed fix (swapping outputs) broke the workflow entirely.
>
> **ACTUAL ROOT CAUSE (v1.3.7):** The SplitInBatches "Done" output passes ALL processed items (7) to the next node, not a single completion signal. The Gmail node executed once per item = 7 emails.
>
> **ACTUAL FIX:** Added "Aggregate Results" Code node between Loop Done output and Email. It receives 7 items and returns 1 item with summary data. Flow: `Loop Done (7 items) → Aggregate Results (1 item) → Send Email (1 email)`

## 1. Objective

The user reported that the n8n workflow `StarTraining Pipeline v1.3` is sending multiple emails (seven, to be exact) instead of a single summary email at the end of the process. The goal is to correct the workflow to send only one email containing links to all the generated designs, as was the intended behavior.

## 2. Analysis of Workflow v1.3

I began by inspecting the workflow definition file: `workflows/StarTraining Pipeline v1.3.json`.

My analysis pinpointed the issue to the `Loop Over Items1` node (a `SplitInBatches` node) and its connections to downstream nodes. In an n8n workflow, the `SplitInBatches` node, when configured as a loop, has two primary outputs:
*   **Output 1 (For Each Batch):** Executes for every single item that the loop processes.
*   **Output 2 (Done):** Executes only once, after the loop has processed all items.

The `connections` object in the JSON file revealed the following incorrect wiring for the `Loop Over Items1` node:

```json
"Loop Over Items1": {
  "main": [
    [
      { "node": "12. Send Email", "type": "main", "index": 0 }
    ],
    [
      { "node": "Prepare a Canva Request1", "type": "main", "index": 0 }
    ]
  ]
},
```

This configuration means:
- **The first output** (for each item) is connected to the **`12. Send Email`** node.
- **The second output** (the "Done" trigger) is connected to the **`Prepare a Canva Request1`** node.

This wiring is the direct cause of the bug. It instructs the workflow to send an email for every item it processes in the loop, while the actual Canva design process is only triggered once the loop believes it's "Done" (which is logically incorrect). The reported seven emails correspond to the seven days of workout data being processed.

## 3. Comparison with Workflow v1.2

For due diligence, I compared the problematic `v1.3` workflow with the version described as the last known good version, `StarTraining Pipeline v1.2 (MAIN + STRENGTH folders) RUNNING VERSION.json`.

Unexpectedly, my analysis showed that the `v1.2` file contains the **exact same incorrect wiring** for its loop node. This finding suggests one of two possibilities:
1.  The file labeled as the "RUNNING VERSION" is not the correct one and also contains the bug.
2.  There is another subtle configuration difference or environmental factor that was masking the bug in v1.2.

Regardless of the state of v1.3, the logic in v1.3 is definitively flawed and requires correction.

## 4. Proposed Solution

To fix the bug, the output connections of the `Loop Over Items1` node must be swapped to follow the correct logic.

### Change Details

I propose modifying the `connections` for `Loop Over Items1` in `workflows/StarTraining Pipeline v1.3.json`.

**From (Incorrect):**
```json
"Loop Over Items1": {
  "main": [
    [
      { "node": "12. Send Email", "type": "main", "index": 0 }
    ],
    [
      { "node": "Prepare a Canva Request1", "type": "main", "index": 0 }
    ]
  ]
},
```

**To (Correct):**
```json
"Loop Over Items1": {
  "main": [
    [
      { "node": "Prepare a Canva Request1", "type": "main", "index": 0 }
    ],
    [
      { "node": "12. Send Email", "type": "main", "index": 0 }
    ]
  ]
},
```

### Justification

This change correctly implements the desired workflow:
1.  The loop's first output will now send each item to the **`Prepare a Canva Request1`** node, beginning the design generation process for that item.
2.  After all items have been processed through the loop, the loop's second ("Done") output will trigger, executing the **`12. Send Email`** node exactly once.

This ensures that the workflow generates all designs first and then sends a single, consolidated email notification, resolving the reported bug.
