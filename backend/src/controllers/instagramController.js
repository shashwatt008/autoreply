const axios = require('axios');
const supabase = require('../config/supabase');

const GRAPH_API = 'https://graph.facebook.com/v18.0';

exports.listAccounts = async (req, res) => {
    const userId = req.user.userId;

    try {
        // Get user's FB access token
        const { data: user, error: userError } = await supabase
            .from('users')
            .select('facebook_user_access_token')
            .eq('id', userId)
            .single();

        if (userError || !user) {
            return res.status(404).json({ error: 'User not found' });
        }

        const accessToken = user.facebook_user_access_token;

        // Get all Facebook pages the user manages
        const pagesRes = await axios.get(`${GRAPH_API}/me/accounts`, {
            params: { access_token: accessToken }
        });

        const pages = pagesRes.data.data || [];
        const igAccounts = [];

        // For each page, check if it has a linked Instagram Business Account
        for (const page of pages) {
            try {
                const igRes = await axios.get(`${GRAPH_API}/${page.id}`, {
                    params: {
                        fields: 'instagram_business_account',
                        access_token: page.access_token
                    }
                });

                if (igRes.data.instagram_business_account) {
                    const igAccountId = igRes.data.instagram_business_account.id;

                    // Get IG account details
                    const igDetailRes = await axios.get(`${GRAPH_API}/${igAccountId}`, {
                        params: {
                            fields: 'id,username,profile_picture_url,followers_count',
                            access_token: page.access_token
                        }
                    });

                    const igData = igDetailRes.data;

                    // Upsert to instagram_accounts table
                    const { data: upserted, error: upsertError } = await supabase
                        .from('instagram_accounts')
                        .upsert({
                            user_id: userId,
                            ig_user_id: igData.id,
                            username: igData.username,
                            profile_picture_url: igData.profile_picture_url,
                            followers_count: igData.followers_count || 0,
                            page_id: page.id
                        }, { onConflict: 'ig_user_id' })
                        .select()
                        .single();

                    if (upsertError) {
                        console.error('IG account upsert error:', upsertError);
                    } else {
                        igAccounts.push(upserted);
                    }
                }
            } catch (pageErr) {
                console.error(`Error fetching IG for page ${page.id}:`, pageErr.response?.data || pageErr.message);
            }
        }

        res.json(igAccounts);
    } catch (err) {
        console.error('List IG Accounts Error:', err.response?.data || err.message);
        res.status(500).json({ error: 'Failed to fetch Instagram accounts' });
    }
};

exports.listMedia = async (req, res) => {
    const userId = req.user.userId;
    const { accountId } = req.params;

    try {
        // Validate user owns this IG account
        const { data: igAccount, error: igError } = await supabase
            .from('instagram_accounts')
            .select('*')
            .eq('id', accountId)
            .eq('user_id', userId)
            .single();

        if (igError || !igAccount) {
            return res.status(404).json({ error: 'Instagram account not found' });
        }

        // Get user's FB access token
        const { data: user, error: userError } = await supabase
            .from('users')
            .select('facebook_user_access_token')
            .eq('id', userId)
            .single();

        if (userError || !user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Get the page access token for this IG account's linked page
        const pagesRes = await axios.get(`${GRAPH_API}/me/accounts`, {
            params: { access_token: user.facebook_user_access_token }
        });

        const page = (pagesRes.data.data || []).find(p => p.id === igAccount.page_id);
        if (!page) {
            return res.status(404).json({ error: 'Linked Facebook page not found' });
        }

        // Fetch media from Instagram Graph API
        const mediaRes = await axios.get(`${GRAPH_API}/${igAccount.ig_user_id}/media`, {
            params: {
                fields: 'id,caption,media_type,media_url,thumbnail_url,timestamp,permalink',
                access_token: page.access_token
            }
        });

        res.json(mediaRes.data.data || []);
    } catch (err) {
        console.error('List IG Media Error:', err.response?.data || err.message);
        res.status(500).json({ error: 'Failed to fetch Instagram media' });
    }
};

exports.saveMedia = async (req, res) => {
    const userId = req.user.userId;
    const { accountId } = req.params;
    const { media } = req.body; // Array of media objects to save

    try {
        // Validate user owns this IG account
        const { data: igAccount, error: igError } = await supabase
            .from('instagram_accounts')
            .select('*')
            .eq('id', accountId)
            .eq('user_id', userId)
            .single();

        if (igError || !igAccount) {
            return res.status(404).json({ error: 'Instagram account not found' });
        }

        if (!media || !Array.isArray(media) || media.length === 0) {
            return res.status(400).json({ error: 'No media provided' });
        }

        const mediaRows = media.map(m => ({
            user_id: userId,
            ig_user_id: igAccount.ig_user_id,
            media_id: m.id,
            caption: m.caption || null,
            media_type: m.media_type || null,
            media_url: m.media_url || null,
            permalink: m.permalink || null
        }));

        const { data, error } = await supabase
            .from('instagram_media')
            .upsert(mediaRows, { onConflict: 'media_id' })
            .select();

        if (error) {
            console.error('Save IG Media Error:', error);
            return res.status(500).json({ error: error.message });
        }

        res.json(data);
    } catch (err) {
        console.error('Save IG Media Error:', err.message);
        res.status(500).json({ error: 'Failed to save Instagram media' });
    }
};
