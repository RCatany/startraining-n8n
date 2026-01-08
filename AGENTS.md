# AI Agents Context - startraining-n8n

## Agent Definition

**Primary Agent Role:** n8n Workflow Automation Assistant

**Capabilities:**
- Configure and troubleshoot n8n workflows
- Debug Docker containerization issues
- Integrate external APIs (Google Drive, Canva, WhatsApp)
- Manage OAuth authentication flows
- Optimize workflow timing and error handling

## Project Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│  StarTraining Automation Pipeline                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  [Google Drive] → [n8n Container] → [Python Pipeline]        │
│                         ↓                                     │
│                   [Canva API] → [WhatsApp API]                │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Agent Workflow Triggers

**Trigger Type:** Google Drive File Watcher
- **Event:** New file created in folder
- **Folder ID:** 1ggqu326-4x_YghpkjTsrg9_AVKpr92Qt
- **File Pattern:** `*.docx`
- **Poll Interval:** Every minute

### Agent Processing Chain (Workflow v1.2)

```
Agent 1: File Detector (Google Drive Trigger)
├─ Input: Google Drive folder monitoring
├─ Output: File metadata (name, id, created_time)
└─ Next: Agent 2

Agent 2: Metadata Extractor (Code Node)
├─ Input: Filename string
├─ Process: Extract date and label using regex
├─ Output: { mondayDate, sourceLabel, fileName, fileId }
└─ Next: Agent 3

Agent 3: Pipeline Orchestrator (HTTP Request)
├─ Input: { file_name }
├─ Action: POST to http://host.docker.internal:5001/run-single
├─ Output: { status, canva_data, canva_data_main, canva_data_strength }
└─ Next: Agent 4

Agent 4: Condition Router (IF Node)
├─ Input: Pipeline status
├─ Condition: status === "success"
├─ True Path: Agent 5 (Folder Prep)
└─ False Path: Error handler

Agent 5: Folder Preparer (Prepare Folders)
├─ Input: mondayDate, sourceLabel
├─ Action: Generate 2 folder items (MAIN, STRENGTH)
├─ Output: [{ suffix: "MAIN" }, { suffix: "STRENGTH" }]
└─ Next: Agent 6

Agent 6: Folder Creator (Create folder)
├─ Input: Folder suffix
├─ Action: Create folder in Google Drive (runs twice)
├─ Output: { folder.id, folder.name }
└─ Next: Agent 7

Agent 7: Folder ID Collector (Collect Folder IDs)
├─ Input: Created folder data
├─ Action: Map folder names to IDs
├─ Output: { folderMap: { MAIN: id1, STRENGTH: id2 } }
└─ Next: Agent 8

Agent 8: Data Loop (Loop Over canva_data)
├─ Input: canva_data array with Type field
├─ Action: Iterate through each workout item
└─ Next: Agent 9 (per item)

Agent 9: Design Creator (Canva Autofill)
├─ Input: Day, Date, Source, Exercise fields
├─ Action: POST to https://api.canva.com/rest/v1/autofills
├─ Output: { job.id }
└─ Next: Agent 10

Agent 10: Wait Controller
├─ Input: Timer trigger
├─ Action: Wait 10 seconds
└─ Next: Agent 11

Agent 11: Autofill Poller (Get Autofill Result)
├─ Input: Autofill job ID
├─ Action: GET to https://api.canva.com/rest/v1/autofills/{id}
├─ Output: { job.result.design.id }
└─ Next: Agent 12

Agent 12: Export Initiator (Canva Export)
├─ Input: Design ID
├─ Action: POST to https://api.canva.com/rest/v1/exports
├─ Output: { job.id }
└─ Next: Agent 13

Agent 13: Wait Controller
├─ Input: Timer trigger
├─ Action: Wait 15 seconds
└─ Next: Agent 14

Agent 14: Export Retriever
├─ Input: Export job ID
├─ Action: GET to https://api.canva.com/rest/v1/exports/{id}
├─ Output: { job.urls[0] }
└─ Next: Agent 15

Agent 15: Image Downloader
├─ Input: Export URL
├─ Action: Download PNG image
├─ Output: Binary image data
└─ Next: Agent 16

Agent 16: File Uploader (Upload file)
├─ Input: Image data, Type field
├─ Action: Upload to MAIN or STRENGTH folder based on Type
├─ Filename: YYYYMMDD_Day_TYPE.png
└─ Next: Agent 17 (or loop back)

Agent 17: Data Collector (Collect Results)
├─ Input: All uploaded file data
├─ Action: Aggregate after loop completes
└─ Next: Agent 18

Agent 18: Notification Sender (Gmail)
├─ Input: Folder links, metadata
├─ Action: Send ONE email with links to both folders
└─ End: Workflow complete
```

## Tool Definitions

### Docker Tools
```yaml
tool: docker_compose
commands:
  - up -d          # Start n8n
  - down           # Stop n8n
  - restart        # Restart after config changes
  - logs -f n8n    # View live logs
```

### Webhook Server Tool
```yaml
tool: webhook_server
location: ~/GitHub/startraining-ai-pipeline
commands:
  start: "source .venv/bin/activate && PORT=5001 python webhook_server.py"
  health_check: "curl http://localhost:5001/health"
endpoints:
  - GET /health
  - POST /run-single
  - POST /run-pipeline
```

### n8n API Tool
```yaml
tool: n8n_workflow
base_url: http://127.0.0.1:5678
actions:
  - import_workflow
  - export_workflow
  - activate_workflow
  - test_execution
file_format: JSON
```

## OAuth Agents

### Google Drive OAuth Agent
```yaml
agent: google_drive_oauth
provider: Google Cloud Platform
console: console.cloud.google.com
credentials:
  client_id: 947653681876-b288b3b0m2ang0ucdlkrtqdjt2447sgi.apps.googleusercontent.com
  client_secret: [stored in n8n]
  redirect_uri: http://127.0.0.1:5678/rest/oauth2-credential/callback
scopes:
  - https://www.googleapis.com/auth/drive.readonly
grant_type: authorization_code
```

### Canva OAuth Agent
```yaml
agent: canva_oauth
provider: Canva
console: canva.dev
credentials:
  client_id: [stored in n8n]
  client_secret: [stored in n8n]
  redirect_uri: http://127.0.0.1:5678/rest/oauth2-credential/callback
scopes:
  - asset:read
  - design:content:read
  - design:content:write
  - brandtemplate:content:read
grant_type: PKCE
critical_notes:
  - Must use 127.0.0.1 (Canva rejects localhost)
  - PKCE required (not Authorization Code)
  - Restart n8n with WEBHOOK_URL=http://127.0.0.1:5678/
```

### WhatsApp Header Auth Agent
```yaml
agent: whatsapp_auth
provider: Meta/Facebook
console: developers.facebook.com
auth_type: Bearer Token
headers:
  Authorization: "Bearer {access_token}"
scopes:
  - whatsapp_business_messaging
```

## Error Handling Patterns

### Pattern 1: OAuth Failure
```yaml
error: "401 Unauthorized"
agent_action:
  - Check credential expiration
  - Re-authorize OAuth connection
  - Verify scopes match requirements
  - For Canva: Ensure 127.0.0.1 is used
```

### Pattern 2: Webhook Timeout
```yaml
error: "ETIMEDOUT" or "ESOCKETTIMEDOUT"
agent_action:
  - Verify webhook_server.py is running
  - Check port 5001 is accessible
  - Increase timeout in HTTP Request node
  - Verify host.docker.internal resolution
```

### Pattern 3: Canva Field Mismatch
```yaml
error: "No matching fields in dataset"
agent_action:
  - Verify template element names match API fields exactly
  - Check case sensitivity (Day vs day, Date vs date)
  - Confirm all required fields are present
  - Test with minimal field set first
```

## Agent Configuration Files

### Primary Config: docker-compose.yml
```yaml
environment_variables:
  N8N_HOST: 127.0.0.1
  WEBHOOK_URL: http://127.0.0.1:5678/
  GENERIC_TIMEZONE: Europe/Madrid
volumes:
  - n8n_data:/home/node/.n8n
extra_hosts:
  - "host.docker.internal:host-gateway"
```

### Workflow Config: workflows/*.json
```json
{
  "nodes": [...],
  "connections": {...},
  "active": true,
  "settings": {
    "executionOrder": "v1"
  }
}
```

## Agent Monitoring

### Health Checks
```bash
# n8n container
docker ps | grep n8n

# Webhook server
curl http://localhost:5001/health

# n8n UI
curl http://127.0.0.1:5678/healthz
```

### Log Monitoring
```bash
# n8n logs
docker compose logs -f n8n

# Webhook server logs
# (visible in terminal where server is running)
```

## Agent Decision Tree (Workflow v1.2)

```
New .docx uploaded to Google Drive
  ↓
Is filename format valid? (YYYYMMDD_semana X CICLO Y *.docx)
  ├─ Yes → Extract date & label → Continue
  └─ No → Throw error "Invalid filename format"

Call webhook server
  ↓
Did pipeline succeed? (status === "success")
  ├─ Yes → canva_data with Type field received → Continue
  └─ No → Log error → Stop workflow

Create MAIN and STRENGTH folders in Google Drive
  ↓
Did folder creation succeed?
  ├─ Yes → Store folder IDs in map → Continue
  └─ No → Check OAuth → Retry

FOR EACH item in canva_data:
  ↓
  Create Canva design (autofill)
    ↓
  Did autofill job complete? (poll for result)
    ├─ Yes → design.id received → Request export
    └─ No → Wait 10s → Poll again

  Export design as PNG
    ↓
  Did export complete? (job.urls available)
    ├─ Yes → Download image
    └─ No → Wait 15s → Poll again

  Upload to Google Drive
    ↓
  Which folder? (based on Type field)
    ├─ Type="MAIN" → Upload to MAIN folder
    └─ Type="STRENGTH" → Upload to STRENGTH folder

  Filename: YYYYMMDD_Day_TYPE.png
  ↓
  → Loop back for next item

After ALL items processed:
  ↓
Send ONE Gmail notification
  ├─ Contains links to MAIN folder
  └─ Contains links to STRENGTH folder
  ↓
End: Workflow complete
```

## Agent Memory/State

**n8n maintains state between nodes:**
- Each node can access previous node outputs using `$node("NodeName").json`
- Workflow execution data stored in n8n database
- Persistent credentials stored in n8n_data volume

**No shared state with Python pipeline:**
- Communication via HTTP webhooks only
- Stateless API calls
- Each workflow execution is independent

## Optimization Guidelines

### Timing Optimization
- Canva render wait: 10 seconds (adjust based on template complexity)
- Export wait: 15 seconds (adjust based on image size)
- Webhook timeout: 300 seconds (5 minutes max for Python pipeline)

### Resource Management
- n8n container: Restart weekly to prevent memory leaks
- Webhook server: Run in production with gunicorn/uvicorn
- Docker volume: Backup n8n_data regularly

### Parallelization
- Current workflow is sequential (required for dependencies)
- Future optimization: Parallel export of multiple designs
- Consider splitting into sub-workflows for complex logic

## Related Agent Systems

**Python Pipeline (startraining-ai-pipeline):**
- Agent A: Word document parser
- Agent B: Exercise data processor
- Agent C: Data pivot transformer
- Agent D: Canva CSV formatter

**Integration Point:** HTTP webhook at /run-single endpoint

<!-- Synchronized: 2026-01-07 -->
