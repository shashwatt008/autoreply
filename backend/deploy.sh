#!/bin/bash
cd "/Users/shashwattiwari/OWN PROJECTS/facebook-auth/backend"

# Step 1: Set project
gcloud config set project autoreply-io-prod

# Step 2: Deploy with env vars from .env file approach
gcloud run deploy autoreply-api \
  --source . \
  --region asia-south1 \
  --allow-unauthenticated \
  --port 3001 \
  --set-env-vars="^##^NODE_ENV=production##APP_ID=2153190152200830##APP_SECRET=ebac29e39ea7d7ea33a8bfc7f190aef2##JWT_SECRET=fb-auto-dm-jwt-secret-2024##FRONTEND_URL=https://autoreply-io.web.app##SUPABASE_URL=https://nxdbczevtehdzgbqfznt.supabase.co##SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im54ZGJjemV2dGVoZHpnYnFmem50Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MzA2NTY1NiwiZXhwIjoyMDg4NjQxNjU2fQ.RouoYGrAyohcGukdaDCyMuVc_l3EaMnr0HaEyUGqZvM##VERIFY_TOKEN=AQBUZSxfPEgtuSUMmv_o2bjD99ZnP8SKP9foTQMhTq2wxw0D2F0bppDettTnp_zsbHTVAF7vP3OQLBbS0YGOS5iphIxz2_aBevVHZnlFKYX1MldcKB2GZCoDC06P0aE4kf0Vy2twnjmrUQopkkGXBpNOYdQ1WFJe9lDFqDjlfpagBuR07ZquxHGX1ks2YHZT4o3JCrDbBsSQJ2b-ru9aAiiUegQadgLi_vFuBI_NEZQxeEra3NZOVvE3n6exYTr0g75GqVoaOZPCJdaRh1ByV8LP23iw6pnQEib1-aANF9gqyhcp4T1mgS9ghmiAVbaWuCydxFOrNzHeSq1S3v3fjVc9Nbye9_caRX8AJsbGAnVgQXcrBX6XSXm7TWrlgwO_KF62jlI7Pqnvd6PYJOO5qiKsw8VHaiXTkP75ppchh5qffUPvWMWBS1yJr0AyWGX_pNdCHOPsWEmX065rJJHCVTko"
