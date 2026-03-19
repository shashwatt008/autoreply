const axios = require('axios');
const supabase = require('../config/supabase');

const VERIFY_TOKEN = process.env.VERIFY_TOKEN;
const GRAPH_API = 'https://graph.facebook.com/v21.0';

exports.verifyWebhook = (req, res) => {
    const mode = req.query['hub.mode'];
    const token = req.query['hub.verify_token'];
    const challenge = req.query['hub.challenge'];

    if (mode && token) {
        if (mode === 'subscribe' && token === VERIFY_TOKEN) {
            console.log('WEBHOOK_VERIFIED');
            res.status(200).send(challenge);
        } else {
            res.sendStatus(403);
        }
    }
};

exports.handleWebhook = async (req, res) => {
    const body = req.body;

    if (body.object === 'page') {
        for (const entry of body.entry) {
            const pageId = entry.id;
            if (entry.changes) {
                for (const change of entry.changes) {
                    if (change.field === 'feed' && change.value.item === 'comment' && change.value.verb === 'add') {
                        await handleComment(pageId, change.value);
                    }
                }
            }
        }
        res.status(200).send('EVENT_RECEIVED');
    } else if (body.object === 'instagram') {
        for (const entry of body.entry) {
            // Handle comment webhooks
            if (entry.changes) {
                for (const change of entry.changes) {
                    if (change.field === 'comments') {
                        await handleInstagramComment(entry.id, change.value);
                    }
                }
            }
            // Handle messaging webhooks (DM replies / quick reply taps)
            if (entry.messaging) {
                for (const msgEvent of entry.messaging) {
                    if (msgEvent.message && !msgEvent.message.is_echo) {
                        await handleInstagramMessage(entry.id, msgEvent);
                    }
                }
            }
        }
        res.status(200).send('EVENT_RECEIVED');
    } else {
        res.sendStatus(404);
    }
};

// ── AI Reply Generator ──────────────────────────────────────────────────────

async function generateAIReply(prompt, commentMessage) {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
        console.warn('OpenAI API key not set, using fallback reply');
        return `Thanks for your comment! We'll get back to you soon.`;
    }

    try {
        const response = await axios.post('https://api.openai.com/v1/chat/completions', {
            model: 'gpt-4o-mini',
            messages: [
                {
                    role: 'system',
                    content: prompt || 'You are a helpful social media assistant. Reply to Facebook comments in a friendly, concise way. Keep replies under 200 characters.'
                },
                {
                    role: 'user',
                    content: `Reply to this Facebook comment: "${commentMessage}"`
                }
            ],
            max_tokens: 150,
            temperature: 0.7
        }, {
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json'
            }
        });

        return response.data.choices[0].message.content.trim();
    } catch (err) {
        console.error('AI Reply Error:', err.response?.data || err.message);
        return 'Thanks for your comment!';
    }
}

// ── Helper: send IG DM ──────────────────────────────────────────────────────

async function sendIgDm(igUserId, recipientId, message, pageAccessToken) {
    return axios.post(`${GRAPH_API}/${igUserId}/messages`, {
        recipient: { id: recipientId },
        message
    }, {
        params: { access_token: pageAccessToken }
    });
}

// ── Helper: get IG account's page access token ──────────────────────────────

async function getIgPageToken(igUserId) {
    const { data: igAccount } = await supabase
        .from('instagram_accounts')
        .select('page_id, username')
        .eq('ig_user_id', igUserId)
        .single();

    if (!igAccount) return null;

    const { data: pageData } = await supabase
        .from('facebook_pages')
        .select('page_access_token')
        .eq('page_id', igAccount.page_id)
        .single();

    if (!pageData) return null;

    return { pageAccessToken: pageData.page_access_token, username: igAccount.username };
}

// ── Facebook Comment Handler (unchanged) ────────────────────────────────────

async function handleComment(pageId, commentData) {
    const { comment_id, post_id, message, from } = commentData;
    if (from.id === pageId) return;

    try {
        const { data: rule, error } = await supabase
            .from('automation_rules')
            .select('*, users(subscription_plan, reply_limit, reply_count, facebook_user_access_token)')
            .eq('post_id', post_id)
            .eq('is_active', true)
            .single();

        if (error || !rule) return;

        const user = rule.users;
        if (user.subscription_plan === 'free' && user.reply_count >= user.reply_limit) {
            console.log('User limit reached. Skipping reply.');
            return;
        }

        let shouldReply = false;
        if (rule.trigger_type === 'all' || rule.trigger_type === 'ai') {
            shouldReply = true;
        } else if (rule.trigger_type === 'keyword') {
            const keywords = rule.keywords || [];
            const lowerMessage = message.toLowerCase();
            if (keywords.some(k => lowerMessage.includes(k.toLowerCase()))) {
                shouldReply = true;
            }
        }

        if (!shouldReply) return;

        const { data: pageData } = await supabase
            .from('facebook_pages')
            .select('page_access_token')
            .eq('page_id', pageId)
            .single();

        if (!pageData) return;
        const pageAccessToken = pageData.page_access_token;

        let replyText = '';
        if (rule.reply_type === 'fixed') {
            const messages = rule.reply_messages || ['Thanks!'];
            replyText = messages[Math.floor(Math.random() * messages.length)];
        } else if (rule.reply_type === 'ai') {
            if (user.subscription_plan !== 'free') {
                replyText = await generateAIReply(rule.ai_prompt, message);
            } else {
                replyText = 'Thanks for your comment!';
            }
        }

        if (replyText) {
            await axios.post(`${GRAPH_API}/${comment_id}/comments`, {
                message: replyText
            }, {
                params: { access_token: pageAccessToken }
            });

            await supabase.rpc('increment_reply_count', { user_id: rule.user_id });
        }

        if (rule.enable_dm && rule.dm_message && user.subscription_plan !== 'free') {
            try {
                await axios.post(`${GRAPH_API}/${comment_id}/private_replies`, {
                    message: rule.dm_message
                }, {
                    params: { access_token: pageAccessToken }
                });
                console.log('DM Sent');
            } catch (dmError) {
                console.error('DM Failed:', dmError.response?.data || dmError.message);
            }
        }

    } catch (e) {
        console.error('Webhook processing error:', e);
    }
}

// ── Instagram Comment Handler ───────────────────────────────────────────────

async function handleInstagramComment(igUserId, commentData) {
    const { media, id: commentId, text, from } = commentData;
    const mediaId = media?.id;
    const commenterId = from?.id;

    if (!commentId || !text || !commenterId) return;
    if (commenterId === igUserId) return;

    try {
        let ruleQuery = supabase
            .from('automation_rules')
            .select('*, users(subscription_plan, reply_limit, reply_count, facebook_user_access_token)')
            .eq('platform', 'instagram')
            .eq('is_active', true);

        if (mediaId) {
            ruleQuery = ruleQuery.eq('post_id', mediaId);
        }

        const { data: rule, error } = await ruleQuery.single();

        if (error || !rule) return;

        const user = rule.users;
        if (user.subscription_plan === 'free' && user.reply_count >= user.reply_limit) {
            console.log('User limit reached. Skipping IG reply.');
            return;
        }

        let shouldReply = false;
        if (rule.trigger_type === 'all' || rule.trigger_type === 'ai') {
            shouldReply = true;
        } else if (rule.trigger_type === 'keyword') {
            const keywords = rule.keywords || [];
            const lowerMessage = text.toLowerCase();
            if (keywords.some(k => lowerMessage.includes(k.toLowerCase()))) {
                shouldReply = true;
            }
        }

        if (!shouldReply) return;

        const tokenInfo = await getIgPageToken(igUserId);
        if (!tokenInfo) return;
        const { pageAccessToken, username } = tokenInfo;

        // ── Comment Reply ──
        // If follow-gate is on, reply with friendly "check your DM" instead of the configured reply
        let commentReplyText = '';
        if (rule.require_follow && rule.file_url && rule.enable_dm && user.subscription_plan !== 'free') {
            // Friendly comment reply — no mention of follow/done
            const friendlyReplies = [
                'Just sent it to your DM! Check your inbox',
                'Check your DM, just sent the link!',
                'Sent it right to your DM!',
                'Just DMed you! Check your messages',
                'It\'s in your DM! Go check it out',
            ];
            commentReplyText = friendlyReplies[Math.floor(Math.random() * friendlyReplies.length)];
        } else if (rule.reply_type === 'fixed') {
            const messages = rule.reply_messages || ['Thanks!'];
            commentReplyText = messages[Math.floor(Math.random() * messages.length)];
        } else if (rule.reply_type === 'ai') {
            if (user.subscription_plan !== 'free') {
                commentReplyText = await generateAIReply(rule.ai_prompt, text);
            } else {
                commentReplyText = 'Thanks for your comment!';
            }
        }

        if (commentReplyText) {
            await axios.post(`${GRAPH_API}/${commentId}/replies`, {
                message: commentReplyText
            }, {
                params: { access_token: pageAccessToken }
            });
            await supabase.rpc('increment_reply_count', { user_id: rule.user_id });
            console.log('IG Comment Reply Sent');
        }

        // ── DM Flow ──
        if (rule.enable_dm && user.subscription_plan !== 'free') {
            try {
                if (rule.require_follow && rule.file_url) {
                    // FOLLOW-GATE FLOW
                    // Step 1: Send friendly "here's your content" DM with "Get Content" button
                    const dmText = rule.dm_message || `Hey! Here's the content you asked for`;
                    await sendIgDm(igUserId, commenterId, {
                        text: dmText,
                        quick_replies: [
                            {
                                content_type: 'text',
                                title: 'Get Content',
                                payload: 'FOLLOW_GATE_GET_CONTENT'
                            }
                        ]
                    }, pageAccessToken);

                    // Save to pending
                    await supabase.from('pending_follow_dms').upsert({
                        user_id: rule.user_id,
                        ig_user_id: igUserId,
                        commenter_ig_id: commenterId,
                        commenter_username: from?.username || null,
                        rule_id: rule.id,
                        comment_id: commentId,
                        file_url: rule.file_url,
                        status: 'pending'
                    }, { onConflict: 'ig_user_id,commenter_ig_id' });

                    console.log('IG Follow-gate DM sent (step 1: Get Content button)');
                } else if (rule.dm_message) {
                    // Normal DM flow
                    await sendIgDm(igUserId, commenterId, {
                        text: rule.dm_message
                    }, pageAccessToken);
                    console.log('IG DM Sent');
                }
            } catch (dmError) {
                console.error('IG DM Failed:', dmError.response?.data || dmError.message);
            }
        }

    } catch (e) {
        console.error('Instagram webhook processing error:', e);
    }
}

// ── Check if user is in last 100 followers ──────────────────────────────────

async function checkIsFollower(igUserId, commenterId, pageAccessToken) {
    try {
        // Fetch last 100 followers only
        const response = await axios.get(`${GRAPH_API}/${igUserId}`, {
            params: {
                fields: 'followers.limit(100){id,username}',
                access_token: pageAccessToken
            }
        });

        const followersData = response.data?.followers;
        if (!followersData || !followersData.data) return false;

        return followersData.data.some(f => f.id === commenterId);
    } catch (err) {
        console.error('Follower check failed:', err.response?.data || err.message);
        return false; // Can't verify = don't give file
    }
}

// ── Handle Instagram DM (quick reply taps + text messages) ──────────────────

async function handleInstagramMessage(igUserId, msgEvent) {
    const senderId = msgEvent.sender?.id;
    const messageText = (msgEvent.message?.text || '').trim();
    const quickReplyPayload = msgEvent.message?.quick_reply?.payload;

    if (!senderId || !messageText) return;

    try {
        // Look up pending follow DM for this sender
        const { data: pending, error } = await supabase
            .from('pending_follow_dms')
            .select('*')
            .eq('ig_user_id', igUserId)
            .eq('commenter_ig_id', senderId)
            .eq('status', 'pending')
            .order('created_at', { ascending: false })
            .limit(1)
            .single();

        if (error || !pending) return; // No pending follow-gate for this user

        const tokenInfo = await getIgPageToken(igUserId);
        if (!tokenInfo) return;
        const { pageAccessToken, username } = tokenInfo;

        // ── Step 2: They tapped "Get Content" ──
        if (quickReplyPayload === 'FOLLOW_GATE_GET_CONTENT' || messageText.toLowerCase() === 'get content') {
            // Check if they already follow
            const isFollower = await checkIsFollower(igUserId, senderId, pageAccessToken);

            if (isFollower) {
                // Already following! Send the file right away
                await sendIgDm(igUserId, senderId, {
                    text: `Here you go! ${pending.file_url}`
                }, pageAccessToken);

                await supabase.from('pending_follow_dms').update({
                    status: 'delivered',
                    updated_at: new Date().toISOString()
                }).eq('id', pending.id);

                console.log('IG File delivered (already following)', senderId);
            } else {
                // Not following — ask them to follow with 2 buttons
                const profileUrl = username ? `https://instagram.com/${username}` : '';
                await sendIgDm(igUserId, senderId, {
                    text: `To get this content, you need to follow us first!\n\n${profileUrl ? `Follow here: ${profileUrl}` : 'Follow our page and come back!'}`,
                    quick_replies: [
                        {
                            content_type: 'text',
                            title: "I'm already following",
                            payload: 'FOLLOW_GATE_CHECK_FOLLOW'
                        }
                    ]
                }, pageAccessToken);
                console.log('IG Follow request sent (not following yet)', senderId);
            }
            return;
        }

        // ── Step 3: They tapped "I'm already following" ──
        const isCheckFollow = quickReplyPayload === 'FOLLOW_GATE_CHECK_FOLLOW'
            || messageText.toLowerCase() === "i'm already following"
            || messageText.toLowerCase() === "im already following"
            || messageText.toLowerCase() === "i am already following";

        if (isCheckFollow) {
            const isFollower = await checkIsFollower(igUserId, senderId, pageAccessToken);

            if (isFollower) {
                // Verified! Send the file
                await sendIgDm(igUserId, senderId, {
                    text: `Here you go! ${pending.file_url}`
                }, pageAccessToken);

                await supabase.from('pending_follow_dms').update({
                    status: 'delivered',
                    updated_at: new Date().toISOString()
                }).eq('id', pending.id);

                console.log('IG File delivered to verified follower', senderId);
            } else {
                // Still not following — send the same follow request again
                const profileUrl = username ? `https://instagram.com/${username}` : '';
                await sendIgDm(igUserId, senderId, {
                    text: `Hmm, we don't see you in our followers yet! Make sure to follow us and try again.\n\n${profileUrl ? `Follow here: ${profileUrl}` : 'Follow our page and come back!'}`,
                    quick_replies: [
                        {
                            content_type: 'text',
                            title: "I'm already following",
                            payload: 'FOLLOW_GATE_CHECK_FOLLOW'
                        }
                    ]
                }, pageAccessToken);
                console.log('IG Follow reminder sent (still not following)', senderId);
            }
            return;
        }

        // If they send anything else and have a pending follow-gate, gently nudge
        // (only if message seems related — short messages, greetings, etc.)
        const nudgeKeywords = ['hi', 'hello', 'hey', 'content', 'file', 'link', 'send', 'give', 'where', 'dm'];
        if (nudgeKeywords.some(k => messageText.toLowerCase().includes(k))) {
            await sendIgDm(igUserId, senderId, {
                text: `Hey! To get the content, just tap the button below.`,
                quick_replies: [
                    {
                        content_type: 'text',
                        title: 'Get Content',
                        payload: 'FOLLOW_GATE_GET_CONTENT'
                    }
                ]
            }, pageAccessToken);
        }

    } catch (e) {
        console.error('Instagram message handling error:', e.response?.data || e.message);
    }
}
