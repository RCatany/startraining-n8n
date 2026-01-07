# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker-based n8n automation workflow that orchestrates the StarTraining workout publishing pipeline. Connects to a Python pipeline via HTTP webhook to process Word documents and publish to Canva/WhatsApp.

## Repository Structure

```
startraining-n8n/
├── docker-compose.yml           # n8n container configuration
├── workflows/                   # Exported n8n workflow JSON files
│   └── startraining_canva_workflow_v1.json
├── Instructions_n8n/            # Setup guides
│   ├── startraining_quickstart.md
│   ├── startraining_n8n_complete_guide.md
│   └── oauth_credentials_setup_guide.md  # OAuth setup for Google & Canva
├── startraining-n8n.txt        # Project status and notes
├── CLAUDE.md                    # Claude AI context (this file)
├── GEMINI.md                    # Gemini AI context
├── AGENTS.md                    # AI agents configuration
└── .cursorrules                 # Cursor AI rules
```

**Related Repository:** `startraining-ai-pipeline` - Python pipeline with Agents A→B→C→D
- Location: `~/GitHub/startraining-ai-pipeline`

## Common Commands

```bash
# Start n8n with Docker Compose
docker compose up -d

# Stop n8n
docker compose down

# View logs
docker compose logs -f n8n

# Restart after config changes
docker compose restart

# Start webhook server (from Python repo)
cd ~/GitHub/startraining-ai-pipeline
source .venv/bin/activate
PORT=5001 python webhook_server.py

# Test webhook health
curl http://localhost:5001/health
```

## Workflow Pipeline (11 Nodes)

1. **Google Drive Trigger** → Detects new `.docx` in `Raw/` folder (ID: 1ggqu326-4x_YghpkjTsrg9_AVKpr92Qt)
2. **Code Node** → Extracts date/label from filename
3. **HTTP Request** → Calls `http://host.docker.internal:5001/run-single`
4. **IF Node** → Checks if pipeline succeeded
5. **Canva Autofill** → Creates design from template (Loop Over Items)
6. **Wait** → 10 seconds for rendering
7. **Export Design** → Requests PNG export
8. **Wait** → 15 seconds for export
9. **Get Export URL** → Retrieves download URL
10. **Collect Export URLs** → Prepares data for notification
11. **Send Gmail** → Notification email (replaced WhatsApp)

## Key URLs

- n8n UI: `http://127.0.0.1:5678` (IMPORTANT: use 127.0.0.1, not localhost - Canva rejects localhost)
- StarTraining Workflow: `http://127.0.0.1:5678/workflow/C7u3mf7UQ9Tnr6EI`
- Webhook Server: `http://localhost:5001` (from host) or `http://host.docker.internal:5001` (from n8n container)

## Docker Configuration Notes

- n8n data persists in Docker volume `n8n_data`
- Use `host.docker.internal` to reach host services from within the container
- Timezone set to `Europe/Madrid`

## External Services Setup

| Service | Console | Required Scopes |
|---------|---------|-----------------|
| Google Drive | console.cloud.google.com | drive.readonly |
| Canva | canva.dev | design:content:read, design:content:write, brandtemplate:content:read |
| WhatsApp | developers.facebook.com | whatsapp_business_messaging |

## Exporting/Importing Workflows

```bash
# Export from n8n UI: Settings → Download Workflow
# Save to: workflows/startraining_canva_workflow_v1.json

# Import: Workflows → Import from File
```

## Current Status (January 7, 2026)

### Completed
- n8n running locally with Docker (v2.1.4)
- Google Drive OAuth connected
- Gmail OAuth connected
- Canva OAuth connected (correct token URL: api.canva.com)
- OAuth credentials setup guide created
- Webhook server operational on port 5001
- Pipeline test successful (agentB.py timeout fixed)
- Canva API field mapping corrected in workflow v1.1

### In Progress
- Testing complete workflow v1.1 end-to-end

### Critical Notes
- **Canva API Field Names**: CASE-SENSITIVE - must match template element names exactly
  - Template elements: DAY, DATE, SOURCE, Body
  - CSV columns mapped: Day→DAY, Date→DATE, Source→SOURCE, Exercise→Body
- **Canva Template ID**: EAG9R2WwCkE
- **Filename Format**: `YYYYMMDD_semana X CICLO Y startrainingbox.docx`

## Canva OAuth Configuration (Critical)

Use these exact settings for Canva OAuth2 in n8n:

| Field | Value |
|-------|-------|
| Grant Type | `Authorization Code with PKCE` |
| Authorization URL | `https://www.canva.com/api/oauth/authorize` |
| Access Token URL | `https://api.canva.com/rest/v1/oauth/token` |
| Scope | `design:content:read design:content:write brandtemplate:content:read` |
| Authentication | `Body` |

**Canva Integration Client ID:** `OC-AZthEnd4uzBU`

See [oauth_credentials_setup_guide.md](Instructions_n8n/oauth_credentials_setup_guide.md) for full setup instructions.

## Troubleshooting

### Canva OAuth Issues
- Must use `127.0.0.1` (NOT `localhost`) - Canva rejects localhost
- Use PKCE grant type (not Authorization Code)
- **Access Token URL must be:** `https://api.canva.com/rest/v1/oauth/token` (NOT `www.canva.com`)

### Webhook Connection Issues
- From n8n container, use `http://host.docker.internal:5001`
- Check webhook server is running: `curl http://localhost:5001/health`
- Increase timeout if needed (default: 300000ms = 5 minutes)

### Canva Template Element Naming
- Element names must match API field names exactly
- Open template → Click element → Rename in Layers/Position panel
- Current template elements: DAY, DATE, SOURCE, Body

<!-- Synchronized: 2026-01-07 -->
