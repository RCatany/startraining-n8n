# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker-based n8n automation workflow that orchestrates the StarTraining workout publishing pipeline. Connects to a Python pipeline via HTTP webhook to process Word documents and publish to Canva/WhatsApp.

## Repository Structure

```
startraining-n8n/
├── docker-compose.yml      # n8n container configuration
├── workflows/              # Exported n8n workflow JSON files
└── startraining-n8n.txt    # Project status and notes
```

**Related Repository:** `startraining-ai-pipeline` - Python pipeline with Agents A→B→C→D

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

## Workflow Pipeline

1. **Google Drive Trigger** → Detects new `.docx` in `Raw/` folder
2. **Code Node** → Extracts date/label from filename
3. **HTTP Request** → Calls `http://host.docker.internal:5001/run-single`
4. **Canva API** → Creates design from template using CSV data
5. **WhatsApp API** → Sends final image

## Key URLs

- n8n UI: `http://localhost:5678`
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
# Save to: workflows/startraining-pipeline.json

# Import: Workflows → Import from File
```
