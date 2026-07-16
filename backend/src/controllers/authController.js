const axios = require('axios');
const jwt = require('jsonwebtoken');
const supabase = require('../config/supabase');

const APP_ID = process.env.APP_ID;
const APP_SECRET = process.env.APP_SECRET;
const REDIRECT_URI = process.env.REDIRECT_URI || 'http://localhost:3001/auth/facebook/callback';
const JWT_SECRET = process.env.JWT_SECRET || 'supersecretkey';
const FRONTEND_URL = process.env.FRONTEND_URL || 'http://localhost:3000';

exports.login = (req, res) => {
    const url = `https://www.facebook.com/v18.0/dialog/oauth?client_id=${APP_ID}&redirect_uri=${REDIRECT_URI}&scope=email,pages_show_list,pages_manage_metadata,pages_messaging,pages_read_engagement,pages_manage_engagement,instagram_basic,instagram_manage_comments,instagram_manage_messages`;
    res.redirect(url);
};

// ── Instagram Login (direct — no Facebook Page required) ────────────────────
// The "API setup with Instagram login" product has its OWN app ID/secret,
// separate from the main Facebook app's APP_ID/APP_SECRET above.

const IG_APP_ID = process.env.IG_APP_ID;
const IG_APP_SECRET = process.env.IG_APP_SECRET;
const IG_REDIRECT_URI = process.env.IG_REDIRECT_URI || 'http://localhost:3001/auth/instagram/callback';
const IG_SCOPES = 'instagram_business_basic,instagram_business_manage_messages,instagram_business_manage_comments';

exports.loginInstagram = (req, res) => {
    const url = `https://www.instagram.com/oauth/authorize?client_id=${IG_APP_ID}&redirect_uri=${encodeURIComponent(IG_REDIRECT_URI)}&scope=${IG_SCOPES}&response_type=code`;
    res.redirect(url);
};

exports.instagramCallback = async (req, res) => {
    const code = req.query.code;
    if (!code) return res.status(400).send('No code received');

    try {
        // 1. Exchange code for a short-lived access token
        const params = new URLSearchParams();
        params.append('client_id', IG_APP_ID);
        params.append('client_secret', IG_APP_SECRET);
        params.append('grant_type', 'authorization_code');
        params.append('redirect_uri', IG_REDIRECT_URI);
        params.append('code', code);

        const shortTokenRes = await axios.post('https://api.instagram.com/oauth/access_token', params);
        const { access_token: shortLivedToken, user_id: igUserId } = shortTokenRes.data;

        // 2. Exchange for a long-lived token (~60 days)
        const longTokenRes = await axios.get('https://graph.instagram.com/access_token', {
            params: {
                grant_type: 'ig_exchange_token',
                client_secret: IG_APP_SECRET,
                access_token: shortLivedToken
            }
        });
        const accessToken = longTokenRes.data.access_token;
        const expiresIn = longTokenRes.data.expires_in;
        const expiresAt = expiresIn ? new Date(Date.now() + expiresIn * 1000) : null;

        // 3. Get the IG profile
        const profileRes = await axios.get('https://graph.instagram.com/v21.0/me', {
            params: {
                fields: 'user_id,username,name,account_type,profile_picture_url',
                access_token: accessToken
            }
        });
        const igProfile = profileRes.data;

        // 4. Upsert User in Supabase, keyed on instagram_user_id
        const { data: user, error } = await supabase
            .from('users')
            .upsert({
                instagram_user_id: String(igProfile.user_id || igUserId),
                name: igProfile.name || igProfile.username,
                subscription_plan: 'free',
                reply_limit: 100,
                reply_count: 0
            }, { onConflict: 'instagram_user_id' })
            .select()
            .single();

        if (error) {
            console.error('Supabase Error:', error);
            return res.status(500).send('Database Error');
        }

        // 5. Upsert the Instagram account with its own direct token — no Page involved
        await supabase.from('instagram_accounts').upsert({
            user_id: user.id,
            ig_user_id: String(igProfile.user_id || igUserId),
            username: igProfile.username,
            profile_picture_url: igProfile.profile_picture_url || null,
            access_token: accessToken,
            token_expires_at: expiresAt,
            page_id: null
        }, { onConflict: 'ig_user_id' });

        // 6. Create JWT and redirect to dashboard
        const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '7d' });
        res.redirect(`${FRONTEND_URL}/dashboard?token=${token}`);

    } catch (err) {
        console.error('Instagram Auth Error:', err.response?.data || err.message);
        res.status(500).send('Instagram Authentication Failed');
    }
};

exports.callback = async (req, res) => {
    const code = req.query.code;
    if (!code) return res.status(400).send('No code received');

    try {
        // 1. Exchange code for access token
        const tokenRes = await axios.get('https://graph.facebook.com/v18.0/oauth/access_token', {
            params: {
                client_id: APP_ID,
                client_secret: APP_SECRET,
                redirect_uri: REDIRECT_URI,
                code
            }
        });

        const accessToken = tokenRes.data.access_token;
        // Calculate expiry if provided (FB usually gives 'expires_in' in seconds)
        const expiresIn = tokenRes.data.expires_in;
        const expiresAt = expiresIn ? new Date(Date.now() + expiresIn * 1000) : null;

        // 2. Get User Info
        const userRes = await axios.get('https://graph.facebook.com/v18.0/me', {
            params: {
                access_token: accessToken,
                fields: 'id,name,email'
            }
        });

        const fbUser = userRes.data;

        // 3. Upsert User in Supabase
        // We use facebook_user_id as unique key
        const { data: user, error } = await supabase
            .from('users')
            .upsert({
                facebook_user_id: fbUser.id,
                name: fbUser.name,
                email: fbUser.email, // might be undefined if no email scope or user denied
                facebook_user_access_token: accessToken,
                token_expires_at: expiresAt,
                // Default values for new users
                subscription_plan: 'free',
                reply_limit: 100,
                reply_count: 0
            }, { onConflict: 'facebook_user_id' })
            .select()
            .single();

        if (error) {
            console.error('Supabase Error:', error);
            return res.status(500).send('Database Error');
        }

        // 4. Create JWT
        const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '7d' });

        // 5. Redirect to Frontend (Dashboard) with token
        // For simplicity, we can pass token in query param or set cookie.
        // Setting httpOnly cookie is safer, but requires frontend to proxy/same-origin.
        // Let's pass via query param to dashboard, and frontend can store in localStorage/cookie.
        // Assuming Frontend is on port 3001 (Next.js default if 3000 taken).
        // Actually, I'll redirect to /dashboard?token=...

        // NOTE: Need to know frontend URL.
        res.redirect(`${FRONTEND_URL}/dashboard?token=${token}`);

    } catch (err) {
        console.error('Auth Error:', err.response?.data || err.message);
        res.status(500).send('Authentication Failed');
    }
};

exports.getMe = async (req, res) => {
    try {
        const { data: user, error } = await supabase
            .from('users')
            .select('*')
            .eq('id', req.user.userId)
            .single();

        if (error || !user) return res.status(404).json({ error: 'User not found' });

        res.json(user);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Meta Data Deletion Callback — required by Facebook
// When user removes app from FB settings, Meta calls this endpoint
exports.deletionCallback = async (req, res) => {
    try {
        const signedRequest = req.body.signed_request;
        if (!signedRequest) return res.status(400).json({ error: 'Missing signed_request' });

        // Parse signed request
        const [encodedSig, payload] = signedRequest.split('.');
        const data = JSON.parse(Buffer.from(payload, 'base64').toString('utf8'));
        const userId = data.user_id;

        if (!userId) return res.status(400).json({ error: 'Invalid request' });

        // Find and delete user by facebook_user_id
        const { data: user } = await supabase
            .from('users')
            .select('id')
            .eq('facebook_user_id', userId)
            .single();

        if (user) {
            // Cascade delete handles pages, posts, rules, etc.
            await supabase.from('users').delete().eq('id', user.id);
        }

        // Return confirmation URL and code as required by Meta
        const confirmationCode = `del_${userId}_${Date.now()}`;
        res.json({
            url: `${process.env.FRONTEND_URL || 'https://autoreply.io'}/deletion?code=${confirmationCode}`,
            confirmation_code: confirmationCode
        });
    } catch (err) {
        console.error('Deletion callback error:', err);
        res.status(500).json({ error: 'Deletion failed' });
    }
};

// Manual deletion request from website form
exports.deletionRequest = async (req, res) => {
    try {
        const { email, fbName } = req.body;
        if (!email) return res.status(400).json({ error: 'Email required' });

        // Find user by email
        const { data: user } = await supabase
            .from('users')
            .select('id')
            .eq('email', email)
            .single();

        if (user) {
            await supabase.from('users').delete().eq('id', user.id);
        }

        res.json({ success: true, message: 'Data deletion request processed' });
    } catch (err) {
        console.error('Deletion request error:', err);
        res.status(500).json({ error: 'Deletion failed' });
    }
};
