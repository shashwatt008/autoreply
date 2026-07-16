const supabase = require('../config/supabase');

// Resolves how to talk to the Graph API for a given IG business account.
// Accounts connected via direct Instagram Login carry their own access_token
// and must be called via graph.instagram.com. Accounts connected the older
// way (Facebook Login -> linked Page) have no access_token of their own and
// are called via graph.facebook.com using the linked Page's token.
async function resolveIgAuth(igUserId) {
    const { data: igAccount } = await supabase
        .from('instagram_accounts')
        .select('access_token, page_id, username')
        .eq('ig_user_id', igUserId)
        .single();

    if (!igAccount) return null;

    if (igAccount.access_token) {
        return {
            accessToken: igAccount.access_token,
            graphBase: 'https://graph.instagram.com/v21.0',
            username: igAccount.username
        };
    }

    if (igAccount.page_id) {
        const { data: pageData } = await supabase
            .from('facebook_pages')
            .select('page_access_token')
            .eq('page_id', igAccount.page_id)
            .single();

        if (pageData?.page_access_token) {
            return {
                accessToken: pageData.page_access_token,
                graphBase: 'https://graph.facebook.com/v21.0',
                username: igAccount.username
            };
        }
    }

    return null;
}

module.exports = { resolveIgAuth };
