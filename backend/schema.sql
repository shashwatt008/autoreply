-- Schema for AutoReply.io (Facebook Auto DM)
-- Run this in Supabase SQL Editor with schema: face_auto_dm

CREATE SCHEMA IF NOT EXISTS face_auto_dm;

-- Users table
CREATE TABLE IF NOT EXISTS face_auto_dm.users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    facebook_user_id TEXT UNIQUE NOT NULL,
    name TEXT,
    email TEXT,
    facebook_user_access_token TEXT,
    token_expires_at TIMESTAMPTZ,
    subscription_plan TEXT DEFAULT 'free' CHECK (subscription_plan IN ('free', 'pro')),
    reply_limit INTEGER DEFAULT 100,
    reply_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Facebook Pages
CREATE TABLE IF NOT EXISTS face_auto_dm.facebook_pages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES face_auto_dm.users(id) ON DELETE CASCADE,
    page_id TEXT UNIQUE NOT NULL,
    page_name TEXT,
    page_access_token TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Facebook Posts (optional cache)
CREATE TABLE IF NOT EXISTS face_auto_dm.facebook_posts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES face_auto_dm.users(id) ON DELETE CASCADE,
    page_id TEXT,
    post_id TEXT UNIQUE NOT NULL,
    post_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Automation Rules
CREATE TABLE IF NOT EXISTS face_auto_dm.automation_rules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES face_auto_dm.users(id) ON DELETE CASCADE,
    page_id TEXT,
    post_id TEXT,
    trigger_type TEXT DEFAULT 'all' CHECK (trigger_type IN ('all', 'keyword', 'ai')),
    keywords TEXT[],
    reply_type TEXT DEFAULT 'fixed' CHECK (reply_type IN ('fixed', 'ai')),
    reply_messages TEXT[],
    webhook_url TEXT,
    ai_prompt TEXT,
    enable_dm BOOLEAN DEFAULT FALSE,
    dm_message TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Instagram Accounts
CREATE TABLE IF NOT EXISTS face_auto_dm.instagram_accounts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES face_auto_dm.users(id) ON DELETE CASCADE,
    ig_user_id TEXT UNIQUE NOT NULL,
    username TEXT,
    profile_picture_url TEXT,
    followers_count INTEGER DEFAULT 0,
    page_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Instagram Media
CREATE TABLE IF NOT EXISTS face_auto_dm.instagram_media (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES face_auto_dm.users(id) ON DELETE CASCADE,
    ig_user_id TEXT,
    media_id TEXT UNIQUE NOT NULL,
    caption TEXT,
    media_type TEXT,
    media_url TEXT,
    permalink TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add platform column to automation_rules
ALTER TABLE face_auto_dm.automation_rules ADD COLUMN IF NOT EXISTS platform TEXT DEFAULT 'facebook' CHECK (platform IN ('facebook', 'instagram'));

-- RPC function to increment reply count
CREATE OR REPLACE FUNCTION face_auto_dm.increment_reply_count(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE face_auto_dm.users
    SET reply_count = reply_count + 1, updated_at = NOW()
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Enable RLS
ALTER TABLE face_auto_dm.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE face_auto_dm.facebook_pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE face_auto_dm.facebook_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE face_auto_dm.automation_rules ENABLE ROW LEVEL SECURITY;

-- Service role policies (backend uses service key)
CREATE POLICY "Service role full access" ON face_auto_dm.users FOR ALL USING (true);
CREATE POLICY "Service role full access" ON face_auto_dm.facebook_pages FOR ALL USING (true);
CREATE POLICY "Service role full access" ON face_auto_dm.facebook_posts FOR ALL USING (true);
CREATE POLICY "Service role full access" ON face_auto_dm.automation_rules FOR ALL USING (true);

ALTER TABLE face_auto_dm.instagram_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE face_auto_dm.instagram_media ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service role full access" ON face_auto_dm.instagram_accounts FOR ALL USING (true);
CREATE POLICY "Service role full access" ON face_auto_dm.instagram_media FOR ALL USING (true);

-- Bulk Reply Jobs
CREATE TABLE IF NOT EXISTS face_auto_dm.bulk_reply_jobs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES face_auto_dm.users(id) ON DELETE CASCADE,
    platform TEXT NOT NULL CHECK (platform IN ('facebook', 'instagram')),
    page_id TEXT,
    post_id TEXT,
    reply_type TEXT DEFAULT 'fixed' CHECK (reply_type IN ('fixed', 'ai')),
    reply_messages TEXT[],
    ai_prompt TEXT,
    enable_dm BOOLEAN DEFAULT FALSE,
    dm_message TEXT,
    min_delay_seconds INTEGER DEFAULT 30,
    max_delay_seconds INTEGER DEFAULT 120,
    total_comments INTEGER DEFAULT 0,
    replied_count INTEGER DEFAULT 0,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'paused', 'completed', 'failed')),
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE face_auto_dm.bulk_reply_jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service role full access" ON face_auto_dm.bulk_reply_jobs FOR ALL USING (true);

-- Track individual comment replies in bulk jobs
CREATE TABLE IF NOT EXISTS face_auto_dm.bulk_reply_comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    job_id UUID REFERENCES face_auto_dm.bulk_reply_jobs(id) ON DELETE CASCADE,
    comment_id TEXT NOT NULL,
    commenter_id TEXT,
    commenter_name TEXT,
    comment_message TEXT,
    reply_sent BOOLEAN DEFAULT FALSE,
    dm_sent BOOLEAN DEFAULT FALSE,
    reply_text TEXT,
    error TEXT,
    replied_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE face_auto_dm.bulk_reply_comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service role full access" ON face_auto_dm.bulk_reply_comments FOR ALL USING (true);

-- Follow-gate DM: new columns on bulk_reply_jobs
ALTER TABLE face_auto_dm.bulk_reply_jobs ADD COLUMN IF NOT EXISTS require_follow BOOLEAN DEFAULT FALSE;
ALTER TABLE face_auto_dm.bulk_reply_jobs ADD COLUMN IF NOT EXISTS file_url TEXT;

-- Follow-gate DM: new columns on automation_rules
ALTER TABLE face_auto_dm.automation_rules ADD COLUMN IF NOT EXISTS require_follow BOOLEAN DEFAULT FALSE;
ALTER TABLE face_auto_dm.automation_rules ADD COLUMN IF NOT EXISTS file_url TEXT;

-- Pending follow DMs: tracks commenters waiting to follow before getting the file
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

-- One pending DM per commenter per IG account
CREATE UNIQUE INDEX IF NOT EXISTS pending_follow_dms_unique
    ON face_auto_dm.pending_follow_dms (ig_user_id, commenter_ig_id);

ALTER TABLE face_auto_dm.pending_follow_dms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service role full access" ON face_auto_dm.pending_follow_dms FOR ALL USING (true);
