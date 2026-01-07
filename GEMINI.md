# Gemini AI Context - startraining-n8n

## Your Role
You are assisting with a Docker-based n8n automation workflow that orchestrates the StarTraining workout publishing pipeline.

## Project Overview

**Purpose:** Automate end-to-end workout publishing from Word documents to WhatsApp messages.

**Architecture:**
- **n8n Container**: Workflow orchestration engine
- **Python Pipeline**: Separate repository (startraining-ai-pipeline) with AI agents
- **External APIs**: Google Drive, Canva, WhatsApp

**Pipeline Flow:**
1. Google Drive detects new .docx file in Raw/ folder
2. Code node extracts date/label from filename
3. HTTP request triggers Python webhook server
4. Python agents (A→B→C→D) process document and generate CSV
5. Canva API creates design from template using CSV data
6. WhatsApp API sends final image

## Repository Structure

```
startraining-n8n/
├── docker-compose.yml           # n8n container config
├── workflows/                   # n8n workflow JSON exports
│   └── startraining_canva_workflow_v1.json
├── Instructions_n8n/            # Setup guides
│   ├── startraining_quickstart.md
│   └── startraining_n8n_complete_guide.md
├── startraining-n8n.txt        # Project status & notes
├── CLAUDE.md                    # Claude AI context
├── GEMINI.md                    # This file
└── .cursorrules                 # Cursor AI rules
```

## Related Repositories

**startraining-ai-pipeline** - Python pipeline with Agents A→B→C→D
- Location: `~/GitHub/startraining-ai-pipeline`
- Contains: webhook_server.py, run_pipeline.py, agents/, config.py, .env

## Essential Commands

### Start n8n
```bash
docker compose up -d
```

### Stop n8n
```bash
docker compose down
```

### View Logs
```bash
docker compose logs -f n8n
```

### Restart After Configuration Changes
```bash
docker compose restart
```

### Start Webhook Server (Separate Terminal)
```bash
cd ~/GitHub/startraining-ai-pipeline
source .venv/bin/activate
PORT=5001 python webhook_server.py
```

### Test Webhook Health
```bash
curl http://localhost:5001/health
```

## Key URLs

| Service | URL | Notes |
|---------|-----|-------|
| n8n UI | http://127.0.0.1:5678 | Use 127.0.0.1, NOT localhost (Canva requirement) |
| StarTraining Workflow | http://127.0.0.1:5678/workflow/C7u3mf7UQ9Tnr6EI | Direct link to workflow |
| Webhook Server (host) | http://localhost:5001 | From your machine |
| Webhook Server (n8n) | http://host.docker.internal:5001 | From n8n container |

## Docker Configuration

### Volumes
- n8n data persists in Docker volume `n8n_data`
- Never manually edit files in `.n8n/` directory

### Networking
- Use `host.docker.internal` to reach host services from container
- Port 5678 exposed for n8n web UI
- Extra host mapping configured for webhook server access

### Environment
- Timezone: `Europe/Madrid`
- Webhook URL: `http://127.0.0.1:5678/`

## External Services

### Google Drive API
- **Console:** console.cloud.google.com
- **Project:** n8n-connector
- **Scopes:** drive.readonly
- **OAuth Redirect:** http://127.0.0.1:5678/rest/oauth2-credential/callback
- **Monitored Folder:** Raw/ (ID: 1ggqu326-4x_YghpkjTsrg9_AVKpr92Qt)

### Canva API
- **Console:** canva.dev
- **Scopes:** design:content:read, design:content:write, brandtemplate:content:read
- **OAuth Type:** PKCE (required)
- **Critical:** Must use 127.0.0.1, NOT localhost (Canva rejects localhost)
- **Template ID:** EAG9R2WwCkE

### WhatsApp Business API
- **Console:** developers.facebook.com
- **Scope:** whatsapp_business_messaging

## Workflow Structure (11 Nodes)

1. **Google Drive Trigger** - Watch for new .docx files
2. **Code Node** - Extract date & label from filename
3. **HTTP Request** - Call webhook_server.py
4. **IF Node** - Check pipeline success
5. **Canva Autofill** - Create design from template (Loop Over Items)
6. **Wait** - 10 seconds for rendering
7. **Export Design** - Request PNG export
8. **Wait** - 15 seconds for export
9. **Get Export URL** - Retrieve download URL
10. **Collect Export URLs** - Prepare data
11. **Send Gmail** - Notification email

## Important Guidelines

### API Field Names
- Canva API field names are CASE-SENSITIVE
- Template element names must match exactly:
  - Day, Date, Source, Exercise, Category, Block
  - Cues_Beginner, Cues_Intermediate, Cues_RX

### Filename Format
- Expected: `YYYYMMDD_semana X CICLO Y startrainingbox.docx`
- Example: `20250113_semana 1 CICLO 7 startrainingbox.docx`

### Export/Import Workflows
```bash
# Export from n8n UI: Settings → Download Workflow
# Save to: workflows/startraining-pipeline.json

# Import: Workflows → Import from File
```

## Current Status (as of 2026-01-05)

### Completed
- n8n running locally with Docker
- Google Drive OAuth connected
- Canva OAuth connected (PKCE fix applied)
- Webhook server operational
- Pipeline test successful (agentB.py timeout fixed)
- Canva API field names corrected

### In Progress
- Testing complete workflow end-to-end
- Verifying Canva template element naming

### Known Issues
- Canva template element names must match API field names exactly
- Root cause: Field names are case-sensitive and were mismatched

## Troubleshooting

### Canva OAuth Issues
- Ensure n8n is accessed via `http://127.0.0.1:5678` (not localhost)
- Verify WEBHOOK_URL environment variable is set
- Use PKCE grant type (not Authorization Code)

### Webhook Connection Issues
- Check webhook server is running on port 5001
- From n8n container, use `http://host.docker.internal:5001`
- Verify extra_hosts configuration in docker-compose.yml

### Pipeline Timeout
- Increase timeout in HTTP Request node (default: 300000ms = 5 minutes)
- Check webhook_server.py logs for errors

## Contact & Documentation

**Key Documents:**
- Project Status: `startraining-n8n.txt`
- Quick Start: `Instructions_n8n/startraining_quickstart.md`
- Complete Guide: `Instructions_n8n/startraining_n8n_complete_guide.md`

**External Documentation:**
- n8n Community: community.n8n.io
- Canva API Docs: canva.dev/docs
- WhatsApp API: developers.facebook.com/docs/whatsapp

<!-- Synchronized: 2026-01-05 16:30 -->
