const axios = require('axios');
const supabase = require('../config/supabase');

exports.listPages = async (req, res) => {
    const userId = req.user.userId;

    try {
        // 1. Get User's FB Access Token from DB
        const { data: user, error: userError } = await supabase
            .from('users')
            .select('facebook_user_access_token')
            .eq('id', userId)
            .single();

        if (userError || !user) return res.status(404).json({ error: 'User not found' });

        // 2. Fetch Pages from Facebook
        // We try to fetch from FB to get latest, then update DB.
        // Or we can just read from DB if we sync on login. 
        // Plan said: "Fetch posts of selected page", but for Pages "Fetch user's pages from DB (or sync with FB)".
        // Let's sync with FB to be safe.

        // Check if token is valid? Controller logic says "You fetch their PAGES".

        const pagesRes = await axios.get('https://graph.facebook.com/v18.0/me/accounts', {
            params: { access_token: user.facebook_user_access_token }
        });

        const fbPages = pagesRes.data.data; // Array of pages

        // 3. Upsert Pages in Supabase
        // We want to return what's in DB (to store local setttings like 'is_connected').

        const upsertPromises = fbPages.map(page => {
            return supabase
                .from('facebook_pages')
                .upsert({
                    user_id: userId,
                    page_id: page.id,
                    page_name: page.name,
                    page_access_token: page.access_token,
                    // catch-all for other fields if needed
                }, { onConflict: 'page_id' })
                .select();
        });

        await Promise.all(upsertPromises);

        // 4. Return all pages from DB for this user
        const { data: pages, error: pagesError } = await supabase
            .from('facebook_pages')
            .select('*')
            .eq('user_id', userId);

        if (pagesError) throw pagesError;

        res.json(pages);

    } catch (error) {
        console.error('Page Fetch Error:', error.response?.data || error.message);
        res.status(500).json({ error: 'Failed to fetch pages' });
    }
};
