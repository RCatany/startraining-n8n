# startraining_n8n Automation - Complete Beginner's Guide

## 🎯 What We're Building

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   📁 Google Drive          🐍 Your Pipeline           🎨 Canva             │
│   ┌─────────────┐         ┌─────────────┐           ┌─────────────┐        │
│   │  New .docx  │ ──────► │ Agents      │ ────────► │  Template   │        │
│   │  uploaded   │         │ A→B→C→D     │           │  Autofill   │        │
│   └─────────────┘         └─────────────┘           └─────────────┘        │
│         │                        │                         │               │
│         │                        │                         ▼               │
│         │                        │                  ┌─────────────┐        │
│         │                        │                  │   Export    │        │
│         │                        │                  │   as PNG    │        │
│         │                        │                  └─────────────┘        │
│         │                        │                         │               │
│         │                        │                         ▼               │
│         │                        │                  ┌─────────────┐        │
│         │                        │                  │  WhatsApp   │        │
│         │                        │                  │   Send      │        │
│         │                        │                  └─────────────┘        │
│         │                        │                                         │
│         └────────────────────────┴──── n8n orchestrates all of this ──────┘
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Prerequisites Checklist

Before starting, make sure you have:

- [ ] Your StarTraining Python pipeline working locally (`python run_all_pipeline.py` runs successfully)
- [ ] A Google account with Google Drive
- [ ] A Canva account (Pro or Team - required for API access)
- [ ] A Meta/Facebook Business account (for WhatsApp)
- [ ] About 1-2 hours to set everything up

---

## Part 1: Install n8n (15 minutes)

### Option A: n8n Cloud (Easiest - Recommended for Beginners)

1. Go to [n8n.io](https://n8n.io)
2. Click **"Get Started Free"**
3. Create an account
4. You'll get a URL like `https://your-name.app.n8n.cloud`

✅ **Done!** Skip to Part 2.

### Option B: Self-Host with Docker (More Control)

If you have Docker installed:

```bash
# Create a folder for n8n data
mkdir ~/n8n-data

# Run n8n
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/n8n-data:/home/node/.n8n \
  n8nio/n8n
```

Open `http://localhost:5678` in your browser.

### Option C: npm Install

```bash
npm install n8n -g
n8n start
```

Open `http://localhost:5678` in your browser.

---

## Part 2: Set Up Your Webhook Server (20 minutes)

Your Python pipeline needs to be accessible from the internet so n8n can trigger it.

### Step 2.1: Install ngrok (for testing)

ngrok creates a public URL that tunnels to your local machine.

1. Go to [ngrok.com](https://ngrok.com) and create a free account
2. Download ngrok for your system
3. Unzip and install it
4. Connect your account:

```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN
```

### Step 2.2: Start Your Webhook Server

Open **Terminal 1**:

```bash
cd /path/to/startraining-ai-pipeline
source .venv/bin/activate
pip install flask  # if not already installed
python webhook_server.py
```

You should see:
```
Starting Startraining Pipeline Webhook Server on port 5000
API Key authentication: disabled

Endpoints:
  GET  /health       - Health check
  POST /run-pipeline - Run full pipeline (all files)
  POST /run-single   - Run pipeline for single file
```

### Step 2.3: Expose with ngrok

Open **Terminal 2**:

```bash
ngrok http 5000
```

You'll see something like:
```
Forwarding    https://abc123xyz.ngrok.io -> http://localhost:5000
```

📝 **Copy that URL!** (e.g., `https://abc123xyz.ngrok.io`)

### Step 2.4: Test the Webhook

Open **Terminal 3** or your browser:

```bash
curl https://abc123xyz.ngrok.io/health
```

Should return: `{"status": "healthy", "service": "startraining-pipeline"}`

✅ **Your webhook is ready!**

---

## Part 3: Get Google Drive Folder IDs (10 minutes)

### Step 3.1: Find Your Folder IDs

1. Open Google Drive in your browser
2. Navigate to your `Blackboard/Raw` folder
3. Look at the URL - it looks like:
   ```
   https://drive.google.com/drive/folders/1ABC123XYZ789
   ```
4. The folder ID is: `1ABC123XYZ789`

**Get IDs for these folders:**
| Folder | What it's for | Your ID |
|--------|---------------|---------|
| `Raw/` | Where you upload .docx files | _____________ |
| `AgentD/` | Where CSVs are generated | _____________ |

### Step 3.2: Create Google Cloud Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click **Select a Project** → **New Project**
3. Name it "startraining-n8n" → **Create**
4. Wait for it to create, then select it

5. Enable Google Drive API:
   - Go to **APIs & Services** → **Library**
   - Search "Google Drive API"
   - Click it → **Enable**

6. Create OAuth Credentials:
   - Go to **APIs & Services** → **Credentials**
   - Click **+ Create Credentials** → **OAuth Client ID**
   - If asked to configure consent screen:
     - Choose **External** → **Create**
     - App name: "startraining-n8n"
     - User support email: your email
     - Developer contact: your email
     - Click **Save and Continue** through all steps
     - Add yourself as a test user
   - Back to Credentials → **+ Create Credentials** → **OAuth Client ID**
   - Application type: **Web application**
   - Name: "n8n"
   - Authorized redirect URIs: Add your n8n callback URL:
     - For n8n Cloud: `https://your-name.app.n8n.cloud/rest/oauth2-credential/callback`
     - For self-hosted: `http://localhost:5678/rest/oauth2-credential/callback`
   - Click **Create**

7. **Copy the Client ID and Client Secret** - you'll need these!

---

## Part 4: Set Up Canva API (20 minutes)

### Step 4.1: Create Canva Developer Integration

1. Go to [Canva Developers](https://www.canva.dev/)
2. Sign in with your Canva account
3. Click **Your integrations** → **Create an integration**
4. Choose **Public** integration type
5. Name: "StarTraining n8n"
6. Description: "Automate workout designs"

> **Note**: You need an **Integration** (not an App). Apps run inside Canva; Integrations connect external services.

### Step 4.2: Configure Scopes

In your integration settings → **Scopes**, enable:
- `asset:read` ✅
- `brandtemplate:content:read` ✅
- `brandtemplate:meta:read` ✅
- `design:content:read` ✅
- `design:content:write` ✅
- `design:permission:read` ✅
- `design:permission:write` ✅

### Step 4.3: Get OAuth Credentials

1. In your integration settings, find:
   - **Client ID**: (copy this)
   - **Client Secret**: Click **Generate secret** and copy it

2. Add redirect URL in **Authentication** → **Redirect URLs**:

   > **IMPORTANT**: Canva does NOT accept `localhost`. You MUST use `127.0.0.1`

   ```
   http://127.0.0.1:5678/rest/oauth2-credential/callback
   ```

   For n8n Cloud: `https://your-name.app.n8n.cloud/rest/oauth2-credential/callback`

### Step 4.4: Configure n8n for Canva OAuth (CRITICAL)

Canva requires **PKCE authentication**. To make this work with self-hosted n8n:

1. **Stop n8n and restart with WEBHOOK_URL**:
   ```bash
   docker stop n8n
   docker rm n8n
   docker run -d --restart unless-stopped --name n8n \
     -p 5678:5678 \
     -e WEBHOOK_URL=http://127.0.0.1:5678/ \
     -v ~/.n8n:/home/node/.n8n \
     n8nio/n8n
   ```

2. **Access n8n via `127.0.0.1` (NOT `localhost`)**:
   ```
   http://127.0.0.1:5678
   ```

3. **Create OAuth2 credential in n8n**:
   - Go to **Credentials** → **Add Credential** → **OAuth2 API**
   - Configure:

   | Field | Value |
   |-------|-------|
   | Grant Type | **PKCE** |
   | Authorization URL | `https://www.canva.com/api/oauth/authorize` |
   | Access Token URL | `https://api.canva.com/rest/v1/oauth/token` |
   | Client ID | *(from Canva)* |
   | Client Secret | *(from Canva)* |
   | Scope | `asset:read design:content:read design:content:write brandtemplate:content:read` |
   | Authentication | **Body** |

4. **Verify the OAuth Redirect URL** shows `127.0.0.1` (not `localhost`)

5. Click **Connect my account** → Authorize in Canva popup

### Step 4.4: Prepare Your Canva Template

1. Open Canva and create or open your workout template
2. For each text element you want to auto-fill:
   - Click the element
   - Click **Position** (top-right)
   - Find **Layer name** and rename it

**Name your layers exactly like this:**

| Layer Name | Content |
|------------|---------|
| `date` | Date of workout |
| `day` | Day name (Lunes, Martes, etc.) |
| `source` | Week/Cycle label |
| `category` | Categories (CROSSTRAINING, STRENGTH, etc.) |
| `exercise` | All exercises concatenated |
| `cues_rx` | RX level cues |
| `cues_intermediate` | Intermediate cues |
| `cues_beginner` | Beginner cues |

3. **Save as Brand Template** (requires Canva Pro/Team)
4. Get the template ID from the URL:
   ```
   https://www.canva.com/design/DAF123ABC.../edit
   ```
   Template ID: `DAF123ABC...`

---

## Part 5: Set Up WhatsApp Business API (30 minutes)

### Step 5.1: Create Meta Business Account

1. Go to [Meta Business Suite](https://business.facebook.com/)
2. Create a business account if you don't have one

### Step 5.2: Set Up WhatsApp Business

1. Go to [Meta for Developers](https://developers.facebook.com/)
2. Click **My Apps** → **Create App**
3. Choose **Business** type
4. App name: "startraining"
5. After creating, click **Add Products** → Find **WhatsApp** → **Set Up**

### Step 5.3: Get WhatsApp Credentials

1. In your app, go to **WhatsApp** → **API Setup**
2. You'll see:
   - **Phone Number ID**: (copy this)
   - **Temporary Access Token**: (copy this - for testing)

3. For a permanent token:
   - Go to **Business Settings** → **System Users**
   - Create a system user
   - Generate a token with `whatsapp_business_messaging` permission

### Step 5.4: Add a Test Phone Number

1. In WhatsApp API Setup, find **To** field
2. Click **Manage phone number list**
3. Add your phone number (for receiving test messages)

---

## Part 6: Build the n8n Workflow (30 minutes)

Now let's put it all together in n8n!

### Step 6.1: Create a New Workflow

1. Open n8n
2. Click **+ Add Workflow**
3. Name it "startraining_pipeline"

### Step 6.2: Add Google Drive Trigger

1. Click the **+** button
2. Search for "Google Drive"
3. Select **Google Drive Trigger**
4. Configure:
   - **Credential**: Click **Create New**
     - Name: "google_drive"
     - Client ID: (paste from Part 3)
     - Client Secret: (paste from Part 3)
     - Click **Connect** and authorize
   - **Trigger On**: Specific Folder
   - **Folder**: Select your `Raw` folder (or paste the folder ID)
   - **Event**: File Created
   - **Poll Times**: Every minute

### Step 6.3: Add Code Node to Extract Info

1. Click **+** after the trigger
2. Search for "Code"
3. Select **Code** node
4. Paste this code:

```javascript
// Extract monday_date and source_label from filename
// Expected format: 20250908_semana 1 CICLO 7 startrainingbox.docx

const fileName = $input.first().json.name;
const name = fileName.replace('.docx', '').replace('.odt', '');

// Extract date (first 8 digits)
const dateMatch = name.match(/^(\d{8})_(.+)$/);
if (!dateMatch) {
  throw new Error(`Invalid filename format: ${fileName}`);
}

const mondayDate = dateMatch[1];
const rest = dateMatch[2];

// Extract semana and ciclo
const labelMatch = rest.match(/[sS]emana\s+(\d+)\s+[cC]ICLO\s+(\d+)/i);
let sourceLabel;

if (labelMatch) {
  sourceLabel = `Semana_${labelMatch[1]}_Ciclo_${labelMatch[2]}`;
} else {
  sourceLabel = rest.replace(/\s+/g, '_');
}

return [{
  json: {
    fileName: fileName,
    fileId: $input.first().json.id,
    mondayDate: mondayDate,
    sourceLabel: sourceLabel
  }
}];
```

### Step 6.4: Add HTTP Request to Run Pipeline

1. Click **+** after the Code node
2. Search for "HTTP Request"
3. Configure:
   - **Method**: POST
   - **URL**: `https://YOUR-NGROK-URL/run-single`
   - **Body Content Type**: JSON
   - **Body**:
   ```json
   {
     "file_name": "{{ $json.fileName }}"
   }
   ```
   - **Options** → **Timeout**: 300000 (5 minutes)

### Step 6.5: Add Wait Node

1. Click **+** after HTTP Request
2. Search for "Wait"
3. Configure:
   - **Wait For**: 5 seconds

### Step 6.6: Add HTTP Request for Canva Autofill

1. Click **+** after Wait
2. Search for "HTTP Request"
3. Configure:
   - **Method**: POST
   - **URL**: `https://api.canva.com/rest/v1/autofills`
   - **Authentication**: Predefined Credential Type → **OAuth2**
   - **OAuth2 API**: Create new:
     - Name: "canva"
     - Authorization URL: `https://www.canva.com/api/oauth/authorize`
     - Token URL: `https://api.canva.com/rest/v1/oauth/token`
     - Client ID: (from Canva)
     - Client Secret: (from Canva)
     - Scope: `design:content:read design:content:write brandtemplate:content:read`
   - **Body Content Type**: JSON
   - **Body**:
   ```json
   {
     "brand_template_id": "YOUR_CANVA_TEMPLATE_ID",
     "data": {
       "date": { "type": "text", "text": "{{ $('Code').item.json.mondayDate }}" },
       "day": { "type": "text", "text": "Lunes" },
       "source": { "type": "text", "text": "{{ $('Code').item.json.sourceLabel }}" }
     }
   }
   ```

### Step 6.7: Add More Wait + Export Nodes

Continue adding:
1. **Wait**: 10 seconds
2. **HTTP Request** to export:
   - Method: POST
   - URL: `https://api.canva.com/rest/v1/designs/{{ $json.job.result.design.id }}/exports`
   - Body: `{"format_type": "png"}`

3. **Wait**: 15 seconds

4. **HTTP Request** to get export URL:
   - Method: GET
   - URL: `https://api.canva.com/rest/v1/exports/{{ $json.job.id }}`

### Step 6.8: Add WhatsApp Send Node

1. Click **+** after the last HTTP Request
2. Search for "HTTP Request"
3. Configure:
   - **Method**: POST
   - **URL**: `https://graph.facebook.com/v18.0/YOUR_PHONE_NUMBER_ID/messages`
   - **Authentication**: Predefined Credential Type → **Header Auth**
   - **Header Auth**: Create new:
     - Name: `Authorization`
     - Value: `Bearer YOUR_WHATSAPP_ACCESS_TOKEN`
   - **Body Content Type**: JSON
   - **Body**:
   ```json
   {
     "messaging_product": "whatsapp",
     "recipient_type": "individual",
     "to": "YOUR_PHONE_NUMBER",
     "type": "image",
     "image": {
       "link": "{{ $json.job.result.urls[0] }}",
       "caption": "🏋️ StarTraining - {{ $('Code').item.json.sourceLabel }}\n\n¡A entrenar! 💪"
     }
   }
   ```

---

## Part 7: Test Your Workflow (10 minutes)

### Step 7.1: Manual Test

1. Make sure your webhook server is running (Terminal 1)
2. Make sure ngrok is running (Terminal 2)
3. In n8n, click **Test Workflow**
4. Upload a test `.docx` file to your Raw folder
5. Watch each node execute (green = success, red = error)

### Step 7.2: Troubleshooting Common Issues

| Problem | Solution |
|---------|----------|
| Google Drive doesn't trigger | Wait up to 1 minute, or check folder ID |
| Webhook timeout | Increase timeout in HTTP Request node |
| Canva auth fails | Re-authorize OAuth, check scopes |
| WhatsApp not sending | Verify phone number format (include country code, no +) |

### Step 7.3: Activate the Workflow

Once testing passes:
1. Click the toggle switch in the top-right to **Activate**
2. Your workflow now runs automatically!

---

## Part 8: Going to Production

### Replace ngrok with a Permanent Server

For production, you need your webhook server always running. Options:

**Option A: Railway (Free tier available)**
1. Push your repo to GitHub
2. Go to [railway.app](https://railway.app)
3. New Project → Deploy from GitHub
4. Select your repo
5. Add environment variables: `OPENAI_API_KEY`, `API_KEY`
6. Get your URL: `https://your-app.railway.app`

**Option B: Render (Free tier available)**
1. Go to [render.com](https://render.com)
2. New → Web Service
3. Connect to GitHub repo
4. Build command: `pip install -r requirements.txt`
5. Start command: `python webhook_server.py`
6. Add environment variables

**Option C: Google Cloud Run**
```bash
# Build and deploy
gcloud run deploy startraining \
  --source . \
  --region europe-west1 \
  --set-env-vars OPENAI_API_KEY=xxx
```

---

## 📁 Quick Reference

### Your Environment Variables

| Variable | Value |
|----------|-------|
| Webhook URL | `https://_______________` |
| Raw Folder ID | `_______________` |
| AgentD Folder ID | `_______________` |
| Canva Template ID | `_______________` |
| Canva Client ID | `_______________` |
| Canva Client Secret | `_______________` |
| WhatsApp Phone Number ID | `_______________` |
| WhatsApp Access Token | `_______________` |
| WhatsApp Recipient | `_______________` |

### Workflow Summary

```
1. Google Drive Trigger (watches Raw folder)
       ↓
2. Code (extracts date + label from filename)
       ↓
3. HTTP Request (POST to /run-single → runs your Python pipeline)
       ↓
4. Wait (5 seconds)
       ↓
5. HTTP Request (POST to Canva autofill)
       ↓
6. Wait (10 seconds)
       ↓
7. HTTP Request (POST to export design)
       ↓
8. Wait (15 seconds)
       ↓
9. HTTP Request (GET export URL)
       ↓
10. HTTP Request (POST to WhatsApp)
```

---

## 🆘 Need Help?

- **n8n Community**: [community.n8n.io](https://community.n8n.io)
- **Canva API Docs**: [canva.dev/docs](https://www.canva.dev/docs/connect/)
- **WhatsApp API**: [developers.facebook.com/docs/whatsapp](https://developers.facebook.com/docs/whatsapp/cloud-api/)

---

## ✅ Success Checklist

- [ ] n8n installed and running
- [ ] Webhook server accessible via public URL
- [ ] Google Drive OAuth working
- [ ] Canva OAuth working
- [ ] WhatsApp credentials set up
- [ ] Test file triggers entire workflow
- [ ] WhatsApp receives image successfully
- [ ] Workflow activated for automatic runs
