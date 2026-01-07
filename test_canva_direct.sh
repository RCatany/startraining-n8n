#!/bin/bash
# Direct test of Canva Autofill API
# Run this to see the actual error message

# You need to get the access token from n8n credentials
# In n8n: Credentials → Your Canva credential → Copy the access token

ACCESS_TOKEN="PASTE_YOUR_TOKEN_HERE"
TEMPLATE_ID="EAG9R2WwCkE"

echo "Testing Canva Autofill API..."
echo ""

curl -X POST "https://api.canva.com/rest/v1/autofills" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "brand_template_id": "'"$TEMPLATE_ID"'",
    "data": {
      "Day": { "type": "text", "text": "Lunes" },
      "Date": { "type": "text", "text": "20260105" },
      "Source": { "type": "text", "text": "Semana_8_Ciclo_8" },
      "Exercise": { "type": "text", "text": "Test exercise content" },
      "Category": { "type": "text", "text": "WOD" },
      "Block": { "type": "text", "text": "Block 1" },
      "Cues_Beginner": { "type": "text", "text": "" },
      "Cues_Intermediate": { "type": "text", "text": "" },
      "Cues_RX": { "type": "text", "text": "" }
    }
  }' \
  -w "\n\nHTTP Status: %{http_code}\n"

echo ""
echo "Template field names (case-sensitive): Day, Date, Source, Exercise, Category, Block, Cues_Beginner, Cues_Intermediate, Cues_RX"
