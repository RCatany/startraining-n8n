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
      "DAY": { "type": "text", "text": "Lunes" },
      "DATE": { "type": "text", "text": "20260105" },
      "SOURCE": { "type": "text", "text": "Semana_8_Ciclo_8" },
      "Body": { "type": "text", "text": "Test exercise content" }
    }
  }' \
  -w "\n\nHTTP Status: %{http_code}\n"

echo ""
echo "If you see an error like 'No matching fields' or 'invalid_field',"
echo "the template element names don't match DAY, DATE, SOURCE, Body"
