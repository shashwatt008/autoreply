const axios = require('axios');
const supabase = require('../config/supabase');

exports.listPosts = async (req, res) => {
    const { pageId } = req.params;
    const userId = req.user.userId;

    try {
        // 1. Get Page Access Token from DB
        const { data: page, error: pageError } = await supabase
            .from('facebook_pages')
            .select('page_access_token')
            .eq('page_id', pageId)
            .eq('user_id', userId) // Ensure ownership
            .single();

        if (pageError || !page) return res.status(404).json({ error: 'Page not found or unauthorized' });

        // 2. Fetch Posts from FB
        const postsRes = await axios.get(`https://graph.facebook.com/v18.0/${pageId}/posts`, {
            params: { access_token: page.page_access_token }
        });

        const fbPosts = postsRes.data.data;

        // 3. Upsert Posts to DB (optional, but good for caching selection state)
        // Actually, we might just want to return them to frontend to select.
        // But if we want to "save selected posts", we need an endpoint for that.
        // For now, let's just return the list from FB.

        // If we want to persist them:
        /*
        const upsertPromises = fbPosts.map(post => {
            return supabase.from('facebook_posts').upsert({
                user_id: userId,
                page_id: pageId,
                post_id: post.id,
                post_message: post.message || '[No Message]'
            }, { onConflict: 'post_id' });
        });
        await Promise.all(upsertPromises);
        */

        res.json(fbPosts);

    } catch (error) {
        console.error('Post Fetch Error:', error.response?.data || error.message);
        res.status(500).json({ error: 'Failed to fetch posts' });
    }
};

exports.savePost = async (req, res) => {
    // Save a selected post to DB for automation
    const { pageId } = req.params;
    const { postId, message } = req.body;
    const userId = req.user.userId;

    // Verify ownership...

    const { data, error } = await supabase
        .from('facebook_posts')
        .upsert({
            user_id: userId,
            page_id: pageId,
            post_id: postId,
            post_message: message
        }, { onConflict: 'post_id' })
        .select();

    if (error) return res.status(500).json({ error: error.message });
    res.json(data);
};
