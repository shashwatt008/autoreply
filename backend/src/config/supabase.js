require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.warn('⚠️ Supabase URL or Service Role Key is missing in .env file. Database operations will fail.');
}

// Initialize Supabase client with service role key for full access
// All DB queries go through backend only — no client-side access
const supabase = createClient(supabaseUrl, supabaseKey, {
    db: {
        schema: 'face_auto_dm'
    }
});

module.exports = supabase;
