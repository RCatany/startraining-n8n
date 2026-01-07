# OAuth Credentials Setup Guide for n8n

This guide documents the complete setup process for connecting Google Drive, Gmail, and Canva to n8n for the StarTraining workflow.

**Last Updated:** January 2026
**n8n Version:** 2.1.4
**n8n URL:** http://127.0.0.1:5678

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Google Cloud Console Setup](#google-cloud-console-setup)
3. [Google Drive OAuth Connection](#google-drive-oauth-connection)
4. [Gmail OAuth Connection](#gmail-oauth-connection)
5. [Canva Integration Setup](#canva-integration-setup)
6. [Canva OAuth Connection](#canva-oauth-connection)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

- [ ] n8n running locally via Docker (`docker compose up -d`)
- [ ] Access to n8n at http://127.0.0.1:5678
- [ ] A Google account for Drive and Gmail
- [ ] A Canva account (Pro recommended for API access)

**Important:** Always use `127.0.0.1` instead of `localhost` - Canva rejects localhost URLs.

---

## Google Cloud Console Setup

Both Google Drive and Gmail use the same Google Cloud project and OAuth credentials.

### Step 1: Create or Select a Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Note the project name (e.g., `n8n-startraining`)

### Step 2: Enable Required APIs

1. Go to **APIs & Services** → **Library**
2. Search and enable:
   - **Google Drive API**
   - **Gmail API**

### Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** user type
3. Fill in required fields:
   - App name: `n8n-startraining`
   - User support email: (your email)
   - Developer contact: (your email)
4. Add scopes:
   - `https://www.googleapis.com/auth/drive.readonly`
   - `https://www.googleapis.com/auth/gmail.send`
5. Add test users (your Google email) if in testing mode
6. Save and continue

### Step 4: Create OAuth Credentials

1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Configure:
   - Application type: **Web application**
   - Name: `n8n-startraining`
   - Authorized redirect URIs:
     ```
     http://127.0.0.1:5678/rest/oauth2-credential/callback
     ```
4. Click **Create**
5. **Save the Client ID and Client Secret** - you'll need these for n8n

---

## Google Drive OAuth Connection

### Step 1: Create Credential in n8n

1. Open n8n: http://127.0.0.1:5678
2. Go to **Settings** (gear icon) → **Credentials**
3. Click **Add Credential**
4. Search for **"Google Drive OAuth2 API"**
5. Click to create

### Step 2: Configure the Credential

| Field | Value |
|-------|-------|
| **Client ID** | (from Google Cloud Console) |
| **Client Secret** | (from Google Cloud Console) |

### Step 3: Connect

1. Click **Sign in with Google**
2. Select your Google account
3. Grant the requested permissions
4. Click **Save**

You should see a green checkmark indicating successful connection.

---

## Gmail OAuth Connection

Gmail uses the same Google Cloud credentials as Google Drive.

### Step 1: Create Credential in n8n

1. Go to **Settings** → **Credentials**
2. Click **Add Credential**
3. Search for **"Gmail OAuth2 API"**
4. Click to create

### Step 2: Configure the Credential

| Field | Value |
|-------|-------|
| **Client ID** | (same as Google Drive) |
| **Client Secret** | (same as Google Drive) |

### Step 3: Connect

1. Click **Sign in with Google**
2. Select your Google account
3. Grant Gmail permissions
4. Click **Save**

---

## Canva Integration Setup

Canva requires creating an Integration (not an App) in the Canva Developer Portal.

### Step 1: Access Canva Developer Portal

1. Go to [Canva Developers](https://www.canva.com/developers/)
2. Sign in with your Canva account
3. Navigate to **Integrations**

### Step 2: Create a New Integration

1. Click **Create an integration** (or open existing)
2. Fill in the integration details:
   - Name: `n8n-startraining`
   - Description: (optional)

### Step 3: Configure Authentication

1. In the integration settings, find **Redirect URLs**
2. Add exactly:
   ```
   http://127.0.0.1:5678/rest/oauth2-credential/callback
   ```
3. Save the changes

### Step 4: Enable Required Scopes

In the **Scopes** section, enable:

- [x] `design:content:read`
- [x] `design:content:write`
- [x] `brandtemplate:content:read`

### Step 5: Get Credentials

1. Find and copy the **Client ID**
2. Generate and copy the **Client Secret**
   - **Important:** Save the secret immediately - you won't see it again

### Step 6: Publish the Integration

Ensure the integration status is **Public** (not just development mode).

---

## Canva OAuth Connection

This is the most complex connection. Follow these steps exactly.

### Step 1: Create Credential in n8n

1. Go to **Settings** → **Credentials**
2. Click **Add Credential**
3. Search for **"OAuth2 API"** (generic OAuth2, not a specific Canva type)
4. Click to create

### Step 2: Configure the Credential

**Critical Settings:**

| Field | Value |
|-------|-------|
| **Grant Type** | `Authorization Code with PKCE` |
| **Authorization URL** | `https://www.canva.com/api/oauth/authorize` |
| **Access Token URL** | `https://api.canva.com/rest/v1/oauth/token` |
| **Client ID** | (your Canva Integration Client ID) |
| **Client Secret** | (your Canva Integration Client Secret) |
| **Scope** | `design:content:read design:content:write brandtemplate:content:read` |
| **Authentication** | `Body` |

**Leave these sections empty:**
- Auth URI Query Parameters
- Authentication Body
- Authentication Header

### Step 3: Connect

1. Use an **incognito/private browser window** (recommended)
2. Click **Connect** or **Sign in**
3. Complete the Canva authorization
4. Click **Save**

---

## Troubleshooting

### Google OAuth Issues

| Problem | Solution |
|---------|----------|
| "Access blocked" error | Add your email as a test user in OAuth consent screen |
| "Redirect URI mismatch" | Ensure the URI in Google Console matches exactly: `http://127.0.0.1:5678/rest/oauth2-credential/callback` |
| API not enabled | Enable Google Drive API and Gmail API in Google Cloud Console |

### Canva OAuth Issues

| Problem | Solution |
|---------|----------|
| `Unsupported content type: text/html` | Wrong Access Token URL. Use: `https://api.canva.com/rest/v1/oauth/token` |
| `{"status":"error","message":"Unauthorized"}` | 1. Regenerate Client Secret in Canva. 2. Try Authentication: `Body` |
| "Insufficient parameters" | Don't test OAuth URL directly in browser - use n8n's Connect button |
| Localhost rejected | Use `127.0.0.1` instead of `localhost` in all URLs |

### General Tips

1. **Always use incognito mode** when troubleshooting OAuth issues
2. **Clear browser cookies** for Google/Canva if having repeated issues
3. **Check n8n logs** for detailed errors:
   ```bash
   docker logs n8n 2>&1 | tail -50
   ```
4. **Restart n8n** after credential changes if issues persist:
   ```bash
   docker compose restart
   ```

---

## Quick Reference: All OAuth URLs

### Google (Drive & Gmail)
- OAuth Consent Screen: https://console.cloud.google.com/apis/credentials/consent
- Credentials: https://console.cloud.google.com/apis/credentials
- Redirect URI: `http://127.0.0.1:5678/rest/oauth2-credential/callback`

### Canva
- Developer Portal: https://www.canva.com/developers/integrations
- Authorization URL: `https://www.canva.com/api/oauth/authorize`
- Access Token URL: `https://api.canva.com/rest/v1/oauth/token`
- Redirect URI: `http://127.0.0.1:5678/rest/oauth2-credential/callback`

---

## Current Configuration (January 2026)

| Service | Client ID | Status |
|---------|-----------|--------|
| Google Drive | (from Google Cloud) | Connected |
| Gmail | (same as Drive) | Connected |
| Canva | `OC-AZthEnd4uzBU` | Connected |

---

**Document Version:** 1.0
**Created:** January 6, 2026
