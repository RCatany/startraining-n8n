# Canva API Debug Guide

## Step 1: Test Node 5 Manually

In n8n, click on node "5. Create Canva Design" and click "Test step".

Check the **OUTPUT** (not input). You should see one of these:

### Success Response:
```json
{
  "job": {
    "id": "some-job-id",
    "status": "in_progress",
    "result": {
      "design": {
        "id": "design-id-here"
      }
    }
  }
}
```

### Error Response (likely what you're seeing):
```json
{
  "code": "invalid_field",
  "message": "No matching fields in dataset"
}
```

Or:
```json
{
  "code": "invalid_request",
  "message": "Field 'DAY' does not exist in the template"
}
```

## Step 2: Fix Template Element Names

Open your Canva Brand Template (ID: EAG9R2WwCkE) and:

1. Click on each text element you want to auto-fill
2. Look for "Position" panel (top right) or "Layers" panel (left sidebar)
3. Find the element/layer name field
4. Rename each element to match EXACTLY:

| Element Name | Content              |
|-------------|----------------------|
| DAY         | Day name (Lunes)     |
| DATE        | Date (20260105)      |
| SOURCE      | Week label           |
| Body        | Exercise text        |

**CRITICAL: Names are case-sensitive!**
- `DAY` is different from `day` or `Day`
- `Body` is different from `body` or `BODY`

## Step 3: Alternative - Update webhook to match your template

If your template already has elements named differently (e.g., lowercase `day`, `date`, `source`, `body`), update the webhook instead.

Edit `/Users/rejc1e11/GitHub/startraining-ai-pipeline/webhook_server.py` lines 76-81:

Change FROM:
```python
canva_row = {
    "DAY": row.get("Day", ""),
    "DATE": row.get("Date", ""),
    "SOURCE": row.get("Source", ""),
    "Body": row.get("Exercise", ""),
}
```

Change TO (lowercase):
```python
canva_row = {
    "day": row.get("Day", ""),
    "date": row.get("Date", ""),
    "source": row.get("Source", ""),
    "body": row.get("Exercise", ""),
}
```

Then update the n8n workflow node 5 JSON body to use lowercase field names.

## Step 4: Test Again

After fixing element names, test node 5 again and look for a successful job response.
