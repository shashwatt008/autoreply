# AutoReply.io — Deployment Guide

## 1. Google Cloud Run (Backend)

### Prerequisites
```bash
brew install --cask google-cloud-sdk
export CLOUDSDK_PYTHON=python3.13
gcloud auth login
```

### First-time setup
```bash
# Create a new project (or use existing)
gcloud projects create autoreply-io-prod --name="AutoReply.io"
gcloud config set project autoreply-io-prod

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

### Deploy
```bash
cd "/Users/shashwattiwari/OWN PROJECTS/facebook-auth/backend"

gcloud run deploy autoreply-api \
  --source . \
  --region asia-south1 \
  --allow-unauthenticated \
  --port 3001 \
  --set-env-vars="NODE_ENV=production" \
  --set-env-vars="APP_ID=2153190152200830" \
  --set-env-vars="APP_SECRET=ebac29e39ea7d7ea33a8bfc7f190aef2" \
  --set-env-vars="JWT_SECRET=fb-auto-dm-jwt-secret-2024" \
  --set-env-vars="FRONTEND_URL=https://autoreply-io.web.app" \
  --set-env-vars="SUPABASE_URL=https://nxdbczevtehdzgbqfznt.supabase.co" \
  --set-env-vars="SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im54ZGJjemV2dGVoZHpnYnFmem50Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MzA2NTY1NiwiZXhwIjoyMDg4NjQxNjU2fQ.RouoYGrAyohcGukdaDCyMuVc_l3EaMnr0HaEyUGqZvM" \
  --set-env-vars="VERIFY_TOKEN=AQBUZSxfPEgtuSUMmv_o2bjD99ZnP8SKP9foTQMhTq2wxw0D2F0bppDettTnp_zsbHTVAF7vP3OQLBbS0YGOS5iphIxz2_aBevVHZnlFKYX1MldcKB2GZCoDC06P0aE4kf0Vy2twnjmrUQopkkGXBpNOYdQ1WFJe9lDFqDjlfpagBuR07ZquxHGX1ks2YHZT4o3JCrDbBsSQJ2b-ru9aAiiUegQadgLi_vFuBI_NEZQxeEra3NZOVvE3n6exYTr0g75GqVoaOZPCJdaRh1ByV8LP23iw6pnQEib1-aANF9gqyhcp4T1mgS9ghmiAVbaWuCydxFOrNzHeSq1S3v3fjVc9Nbye9_caRX8AJsbGAnVgQXcrBX6XSXm7TWrlgwO_KF62jlI7Pqnvd6PYJOO5qiKsw8VHaiXTkP75ppchh5qffUPvWMWBS1yJr0AyWGX_pNdCHOPsWEmX065rJJHCVTko"
```

### After deploy — update REDIRECT_URI
Once you get the Cloud Run URL (e.g. `https://autoreply-api-xxxxx-el.a.run.app`):
```bash
gcloud run services update autoreply-api \
  --region asia-south1 \
  --update-env-vars="REDIRECT_URI=https://autoreply-api-xxxxx-el.a.run.app/auth/facebook/callback"
```

### Add optional env vars later
```bash
gcloud run services update autoreply-api \
  --region asia-south1 \
  --update-env-vars="OPENAI_API_KEY=sk-xxx,RAZORPAY_KEY_ID=rzp_xxx,RAZORPAY_KEY_SECRET=xxx,RAZORPAY_WEBHOOK_SECRET=xxx"
```

### Redeploy after code changes
```bash
cd "/Users/shashwattiwari/OWN PROJECTS/facebook-auth/backend"
gcloud run deploy autoreply-api --source . --region asia-south1
```

---

## 2. UptimeRobot (Keep Alive)

1. Go to https://uptimerobot.com
2. Add New Monitor:
   - Type: HTTP(s)
   - Friendly Name: AutoReply API
   - URL: `https://autoreply-api-xxxxx-el.a.run.app/`
   - Monitoring Interval: 5 minutes
3. Save — this pings the health endpoint every 5 min to prevent cold starts

---

## 3. Supabase — Run New SQL

Go to Supabase Dashboard → SQL Editor → run this:

```sql
-- Follow-gate columns on bulk_reply_jobs
ALTER TABLE face_auto_dm.bulk_reply_jobs ADD COLUMN IF NOT EXISTS require_follow BOOLEAN DEFAULT FALSE;
ALTER TABLE face_auto_dm.bulk_reply_jobs ADD COLUMN IF NOT EXISTS file_url TEXT;

-- Follow-gate columns on automation_rules
ALTER TABLE face_auto_dm.automation_rules ADD COLUMN IF NOT EXISTS require_follow BOOLEAN DEFAULT FALSE;
ALTER TABLE face_auto_dm.automation_rules ADD COLUMN IF NOT EXISTS file_url TEXT;

-- Pending follow DMs table
CREATE TABLE IF NOT EXISTS face_auto_dm.pending_follow_dms (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES face_auto_dm.users(id) ON DELETE CASCADE,
    ig_user_id TEXT NOT NULL,
    commenter_ig_id TEXT NOT NULL,
    commenter_username TEXT,
    rule_id UUID REFERENCES face_auto_dm.automation_rules(id) ON DELETE SET NULL,
    comment_id TEXT,
    file_url TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'delivered', 'expired')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS pending_follow_dms_unique
    ON face_auto_dm.pending_follow_dms (ig_user_id, commenter_ig_id);

ALTER TABLE face_auto_dm.pending_follow_dms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service role full access" ON face_auto_dm.pending_follow_dms FOR ALL USING (true);
```

---

## 4. Facebook Developer Dashboard

App ID: `2153190152200830`
URL: https://developers.facebook.com/apps/2153190152200830

### Settings → Basic
- App Icon: upload one
- Privacy Policy URL: `https://autoreply-io.web.app/privacy`
- Terms of Service URL: `https://autoreply-io.web.app/terms`
- Data Deletion Callback URL: `https://autoreply-io.vercel.app/auth/deletion-callback`
- App Domains: `autoreply-io.web.app`

### Facebook Login → Settings
- Valid OAuth Redirect URIs: `https://autoreply-io.vercel.app/auth/facebook/callback`

### Webhooks
- Callback URL: `https://autoreply-io.vercel.app/webhook`
- Verify Token: (same VERIFY_TOKEN from env)
- Subscribe to fields:
  - **Page**: `feed` (for Facebook comment webhooks)
  - **Instagram**: `comments`, `messages` (comments for auto-reply, messages for follow-gate DM flow)

### Permissions (App Review)
Request these permissions:
- `pages_show_list`
- `pages_read_engagement`
- `pages_manage_metadata`
- `pages_messaging`
- `instagram_basic`
- `instagram_manage_comments`
- `instagram_manage_messages`

### Go Live
- Switch App Mode from **Development** → **Live**

---

## 5. Flutter App — Update Base URL

In `flutter_app/lib/constants/app_constants.dart`:
```dart
static const String apiBaseUrl = 'https://autoreply-api-xxxxx-el.a.run.app';
```

Then build:
```bash
cd "/Users/shashwattiwari/OWN PROJECTS/facebook-auth/flutter_app"
flutter build ipa  # iOS
flutter build apk  # Android
```

---

## 6. Website — Update API URL (optional)

In `website/.env.local`:
```
NEXT_PUBLIC_API_URL=https://autoreply-api-xxxxx-el.a.run.app
```

Rebuild and deploy:
```bash
cd "/Users/shashwattiwari/OWN PROJECTS/facebook-auth/website"
npm run build
firebase deploy
```

---

## 7. Test the Full Flow

1. Open Flutter app → Log in with Facebook
2. Connect Instagram page
3. Create automation rule on a post:
   - Trigger: Keyword (e.g., "free", "send", "link")
   - Reply: Fixed
   - Auto DM: ON
   - Require Follow: ON
   - File URL: your Google Drive / Dropbox link
4. Have someone comment the keyword on the post
5. Expected:
   - Comment reply: "Just sent it to your DM! Check your inbox"
   - DM: "Hey! Here's the content you asked for" + [Get Content] button
   - Tap Get Content → "Follow us first!" + [I'm already following] button
   - Follow + tap button → file delivered
