# StarTraining n8n - Quick Start Checklist

## 🔧 Values You Need to Replace in the Workflow

After importing `startraining_n8n_simple.json`, search and replace these values:

| Placeholder | Where to Find It | Example |
|-------------|------------------|---------|
| `REPLACE_WITH_YOUR_RAW_FOLDER_ID` | Google Drive URL of Raw folder | `1ABC123def456` |
| `REPLACE_WITH_YOUR_WEBHOOK_URL` | Your ngrok or server URL | `https://abc123.ngrok.io` |
| `REPLACE_WITH_YOUR_CANVA_TEMPLATE_ID` | Canva template URL | `DAFabc123xyz` |
| `REPLACE_WITH_YOUR_PHONE_NUMBER_ID` | Meta WhatsApp API Setup | `123456789012345` |
| `REPLACE_WITH_RECIPIENT_PHONE` | Phone to receive messages | `34612345678` |

---

## 📋 Setup Steps (In Order)

### 1. Webhook Server (Your Computer)
```bash
# Terminal 1
cd startraining-ai-pipeline
source .venv/bin/activate
python webhook_server.py

# Terminal 2
ngrok http 5000
# Copy the https://xxx.ngrok.io URL
```

### 2. Import Workflow to n8n
1. Open n8n
2. Click **+** → **Import from file**
3. Select `startraining_n8n_simple.json`
4. Replace all `REPLACE_WITH_...` values

### 3. Create Credentials in n8n

**Google Drive OAuth2:**
- Create at [console.cloud.google.com](https://console.cloud.google.com)
- Enable Google Drive API
- Get Client ID + Secret

**Canva OAuth2:**
- Create at [canva.dev](https://canva.dev)
- Get Client ID + Secret
- Scopes: `design:content:read design:content:write brandtemplate:content:read`

**WhatsApp Header Auth:**
- Name: `Authorization`
- Value: `Bearer YOUR_ACCESS_TOKEN`

### 4. Test
1. Click **Test workflow** in n8n
2. Upload a .docx to your Raw folder
3. Watch the nodes execute

### 5. Activate
- Toggle the workflow ON when testing passes

---

## 🚨 Common Errors

| Error | Fix |
|-------|-----|
| "Invalid filename format" | File must be named like `20251223_semana 4 CICLO 8 startrainingbox.docx` |
| Webhook timeout | Increase timeout in node 3, or check if pipeline is running |
| Canva 401 | Re-authorize OAuth credentials |
| WhatsApp "invalid recipient" | Use format `34612345678` (country code, no +, no spaces) |

---

## 📱 Test WhatsApp First

Before full workflow, test WhatsApp works:

```bash
curl -X POST "https://graph.facebook.com/v18.0/YOUR_PHONE_NUMBER_ID/messages" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "messaging_product": "whatsapp",
    "to": "34612345678",
    "type": "text",
    "text": {"body": "Test from n8n setup!"}
  }'
```

---

## 🎯 Canva Template Layer Names

Name these layers in your Canva template:

| Layer | AgentD CSV Column |
|-------|-------------------|
| `date` | Date |
| `day` | Day |
| `source` | Source |
| `category` | Category |
| `exercise` | Exercise |
| `headcoach` | HeadCoach |
| `cues_rx` | Cues_RX |
| `cues_intermediate` | Cues_Intermediate |
| `cues_beginner` | Cues_Beginner |
