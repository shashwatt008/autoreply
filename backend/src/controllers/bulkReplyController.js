const axios = require('axios');
const supabase = require('../config/supabase');

// ── Helpers ──────────────────────────────────────────────────────────────────

function randomDelay(minSeconds, maxSeconds) {
    const ms = (Math.floor(Math.random() * (maxSeconds - minSeconds + 1)) + minSeconds) * 1000;
    return new Promise(resolve => setTimeout(resolve, ms));
}

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
                    content: prompt || 'You are a helpful social media assistant. Reply to comments in a friendly, concise way. Keep replies under 200 characters.'
                },
                {
                    role: 'user',
                    content: `Reply to this comment: "${commentMessage}"`
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

async function getPageAccessToken(pageId) {
    const { data } = await supabase
        .from('facebook_pages')
        .select('page_access_token')
        .eq('page_id', pageId)
        .single();
    return data?.page_access_token || null;
}

// ── Fetch Comments ───────────────────────────────────────────────────────────

exports.fetchComments = async (req, res) => {
    try {
        const userId = req.user.userId;

        // PRO only check
        const { data: user } = await supabase
            .from('users')
            .select('subscription_plan')
            .eq('id', userId)
            .single();

        if (!user || user.subscription_plan === 'free') {
            return res.status(403).json({ error: 'Bulk reply is a PRO feature. Please upgrade your plan.' });
        }

        const { postId } = req.params;
        const { platform, pageId, accountId } = req.query;

        if (!platform || !postId) {
            return res.status(400).json({ error: 'platform and postId are required' });
        }

        let pageAccessToken = null;
        let comments = [];

        if (platform === 'facebook') {
            if (!pageId) {
                return res.status(400).json({ error: 'pageId query param is required for Facebook' });
            }
            pageAccessToken = await getPageAccessToken(pageId);
            if (!pageAccessToken) {
                return res.status(404).json({ error: 'Page not found or no access token' });
            }

            const response = await axios.get(`https://graph.facebook.com/v18.0/${postId}/comments`, {
                params: {
                    fields: 'id,message,from,created_time',
                    limit: 100,
                    access_token: pageAccessToken
                }
            });

            comments = (response.data.data || [])
                .filter(c => c.from && c.from.id !== pageId) // filter out own comments
                .map(c => ({
                    comment_id: c.id,
                    message: c.message,
                    from_id: c.from?.id,
                    from_name: c.from?.name,
                    timestamp: c.created_time
                }));

        } else if (platform === 'instagram') {
            if (!accountId) {
                return res.status(400).json({ error: 'accountId query param is required for Instagram' });
            }

            // Look up the IG account to find linked page_id
            const { data: igAccount } = await supabase
                .from('instagram_accounts')
                .select('page_id, ig_user_id')
                .eq('ig_user_id', accountId)
                .single();

            if (!igAccount) {
                return res.status(404).json({ error: 'Instagram account not found' });
            }

            pageAccessToken = await getPageAccessToken(igAccount.page_id);
            if (!pageAccessToken) {
                return res.status(404).json({ error: 'Linked page not found or no access token' });
            }

            const response = await axios.get(`https://graph.facebook.com/v18.0/${postId}/comments`, {
                params: {
                    fields: 'id,text,username,from,timestamp',
                    limit: 100,
                    access_token: pageAccessToken
                }
            });

            comments = (response.data.data || [])
                .filter(c => {
                    // Filter out comments from the IG account itself
                    if (c.from && c.from.id === igAccount.ig_user_id) return false;
                    return true;
                })
                .map(c => ({
                    comment_id: c.id,
                    message: c.text,
                    from_id: c.from?.id,
                    from_name: c.username || c.from?.username,
                    timestamp: c.timestamp
                }));
        } else {
            return res.status(400).json({ error: 'platform must be "facebook" or "instagram"' });
        }

        res.json({ comments, total: comments.length });
    } catch (err) {
        console.error('fetchComments error:', err.response?.data || err.message);
        res.status(500).json({ error: 'Failed to fetch comments', details: err.response?.data || err.message });
    }
};

// ── Start Bulk Reply ─────────────────────────────────────────────────────────

exports.startBulkReply = async (req, res) => {
    try {
        const userId = req.user.userId;

        // PRO only check
        const { data: user } = await supabase
            .from('users')
            .select('subscription_plan')
            .eq('id', userId)
            .single();

        if (!user || user.subscription_plan === 'free') {
            return res.status(403).json({ error: 'Bulk reply is a PRO feature. Please upgrade your plan.' });
        }

        const {
            platform,
            page_id,
            post_id,
            comments,
            reply_type = 'fixed',
            reply_messages,
            ai_prompt,
            enable_dm = false,
            dm_message,
            require_follow = false,
            file_url,
            min_delay_seconds = 30,
            max_delay_seconds = 120
        } = req.body;

        if (!platform || !post_id || !comments || !Array.isArray(comments) || comments.length === 0) {
            return res.status(400).json({ error: 'platform, post_id, and a non-empty comments array are required' });
        }

        if (reply_type === 'fixed' && (!reply_messages || reply_messages.length === 0)) {
            return res.status(400).json({ error: 'reply_messages is required when reply_type is "fixed"' });
        }

        // Create the job
        const { data: job, error: jobError } = await supabase
            .from('bulk_reply_jobs')
            .insert({
                user_id: userId,
                platform,
                page_id,
                post_id,
                reply_type,
                reply_messages,
                ai_prompt,
                enable_dm,
                dm_message,
                require_follow,
                file_url,
                min_delay_seconds,
                max_delay_seconds,
                total_comments: comments.length,
                replied_count: 0,
                status: 'running'
            })
            .select()
            .single();

        if (jobError) {
            console.error('Failed to create bulk reply job:', jobError);
            return res.status(500).json({ error: 'Failed to create job', details: jobError.message });
        }

        // Insert all comments
        const commentRows = comments.map(c => ({
            job_id: job.id,
            comment_id: c.comment_id,
            commenter_id: c.commenter_id,
            commenter_name: c.commenter_name,
            comment_message: c.comment_message,
            reply_sent: false,
            dm_sent: false
        }));

        const { error: commentsError } = await supabase
            .from('bulk_reply_comments')
            .insert(commentRows);

        if (commentsError) {
            console.error('Failed to insert bulk reply comments:', commentsError);
            // Mark job as failed
            await supabase.from('bulk_reply_jobs').update({ status: 'failed', error_message: commentsError.message }).eq('id', job.id);
            return res.status(500).json({ error: 'Failed to insert comments', details: commentsError.message });
        }

        // Fire-and-forget background processing
        processBulkReply(job.id).catch(err => {
            console.error('Background bulk reply processing error:', err);
        });

        res.json({
            job_id: job.id,
            status: 'running',
            total_comments: comments.length
        });
    } catch (err) {
        console.error('startBulkReply error:', err.message);
        res.status(500).json({ error: 'Failed to start bulk reply', details: err.message });
    }
};

// ── Background Processing ────────────────────────────────────────────────────

async function processBulkReply(jobId) {
    // Fetch the job
    const { data: job, error: jobError } = await supabase
        .from('bulk_reply_jobs')
        .select('*')
        .eq('id', jobId)
        .single();

    if (jobError || !job) {
        console.error('processBulkReply: job not found', jobId);
        return;
    }

    // Get page access token
    let pageAccessToken = null;
    let igUserId = null;

    if (job.platform === 'facebook') {
        pageAccessToken = await getPageAccessToken(job.page_id);
    } else if (job.platform === 'instagram') {
        // For Instagram, look up the IG account to get ig_user_id and the linked page token
        const { data: igAccount } = await supabase
            .from('instagram_accounts')
            .select('ig_user_id, page_id')
            .eq('page_id', job.page_id)
            .single();

        if (igAccount) {
            igUserId = igAccount.ig_user_id;
            pageAccessToken = await getPageAccessToken(igAccount.page_id);
        }
    }

    if (!pageAccessToken) {
        await supabase.from('bulk_reply_jobs').update({
            status: 'failed',
            error_message: 'Could not retrieve page access token',
            updated_at: new Date().toISOString()
        }).eq('id', jobId);
        return;
    }

    // Fetch unprocessed comments
    const { data: pendingComments, error: commentsError } = await supabase
        .from('bulk_reply_comments')
        .select('*')
        .eq('job_id', jobId)
        .eq('reply_sent', false)
        .order('created_at', { ascending: true });

    if (commentsError || !pendingComments || pendingComments.length === 0) {
        await supabase.from('bulk_reply_jobs').update({
            status: 'completed',
            updated_at: new Date().toISOString()
        }).eq('id', jobId);
        return;
    }

    let successCount = 0;
    let failCount = 0;

    for (const comment of pendingComments) {
        // Re-check job status (user may have paused)
        const { data: currentJob } = await supabase
            .from('bulk_reply_jobs')
            .select('status')
            .eq('id', jobId)
            .single();

        if (!currentJob || currentJob.status !== 'running') {
            console.log(`Bulk reply job ${jobId} is no longer running (status: ${currentJob?.status}). Stopping.`);
            break;
        }

        try {
            const GRAPH_API = 'https://graph.facebook.com/v21.0';

            // Generate reply text
            let replyText = '';
            if (job.platform === 'instagram' && job.require_follow && job.file_url && job.enable_dm) {
                // Follow-gate: friendly "check DM" comment reply
                const friendlyReplies = [
                    'Just sent it to your DM! Check your inbox',
                    'Check your DM, just sent the link!',
                    'Sent it right to your DM!',
                    'Just DMed you! Check your messages',
                ];
                replyText = friendlyReplies[Math.floor(Math.random() * friendlyReplies.length)];
            } else if (job.reply_type === 'fixed') {
                const messages = job.reply_messages || ['Thanks!'];
                replyText = messages[Math.floor(Math.random() * messages.length)];
            } else if (job.reply_type === 'ai') {
                replyText = await generateAIReply(job.ai_prompt, comment.comment_message);
            }

            // Post the reply
            if (job.platform === 'facebook') {
                await axios.post(`${GRAPH_API}/${comment.comment_id}/comments`, {
                    message: replyText
                }, {
                    params: { access_token: pageAccessToken }
                });
            } else if (job.platform === 'instagram') {
                await axios.post(`${GRAPH_API}/${comment.comment_id}/replies`, {
                    message: replyText
                }, {
                    params: { access_token: pageAccessToken }
                });
            }

            // Send DM if enabled
            let dmSent = false;
            if (job.enable_dm && job.platform === 'instagram' && igUserId && job.require_follow && job.file_url) {
                // Follow-gate flow: send "here's your content" + Get Content button
                try {
                    const dmText = job.dm_message || `Hey! Here's the content you asked for`;
                    await axios.post(`${GRAPH_API}/${igUserId}/messages`, {
                        recipient: { id: comment.commenter_id },
                        message: {
                            text: dmText,
                            quick_replies: [
                                {
                                    content_type: 'text',
                                    title: 'Get Content',
                                    payload: 'FOLLOW_GATE_GET_CONTENT'
                                }
                            ]
                        }
                    }, {
                        params: { access_token: pageAccessToken }
                    });

                    await supabase.from('pending_follow_dms').upsert({
                        user_id: job.user_id,
                        ig_user_id: igUserId,
                        commenter_ig_id: comment.commenter_id,
                        commenter_username: comment.commenter_name,
                        comment_id: comment.comment_id,
                        file_url: job.file_url,
                        status: 'pending'
                    }, { onConflict: 'ig_user_id,commenter_ig_id' });

                    dmSent = true;
                } catch (dmErr) {
                    console.error(`Follow-gate DM failed for ${comment.comment_id}:`, dmErr.response?.data || dmErr.message);
                }
            } else if (job.enable_dm && job.dm_message) {
                // Normal DM flow
                try {
                    if (job.platform === 'facebook') {
                        await axios.post(`${GRAPH_API}/${comment.comment_id}/private_replies`, {
                            message: job.dm_message
                        }, {
                            params: { access_token: pageAccessToken }
                        });
                    } else if (job.platform === 'instagram' && igUserId) {
                        await axios.post(`${GRAPH_API}/${igUserId}/messages`, {
                            recipient: { id: comment.commenter_id },
                            message: { text: job.dm_message }
                        }, {
                            params: { access_token: pageAccessToken }
                        });
                    }
                    dmSent = true;
                } catch (dmErr) {
                    console.error(`DM failed for comment ${comment.comment_id}:`, dmErr.response?.data || dmErr.message);
                }
            }

            // Update the comment record
            await supabase.from('bulk_reply_comments').update({
                reply_sent: true,
                dm_sent: dmSent,
                reply_text: replyText,
                replied_at: new Date().toISOString()
            }).eq('id', comment.id);

            // Increment replied_count on the job
            successCount++;
            await supabase.from('bulk_reply_jobs').update({
                replied_count: job.replied_count + successCount,
                updated_at: new Date().toISOString()
            }).eq('id', jobId);

        } catch (err) {
            console.error(`Error replying to comment ${comment.comment_id}:`, err.response?.data || err.message);
            failCount++;

            // Save error to comment but continue
            await supabase.from('bulk_reply_comments').update({
                error: err.response?.data?.error?.message || err.message
            }).eq('id', comment.id);
        }

        // Wait random delay before next comment
        await randomDelay(job.min_delay_seconds, job.max_delay_seconds);
    }

    // Update final job status
    const finalStatus = (successCount === 0 && failCount > 0) ? 'failed' : 'completed';
    const errorMessage = (finalStatus === 'failed') ? 'All comment replies failed' : null;

    await supabase.from('bulk_reply_jobs').update({
        status: finalStatus,
        error_message: errorMessage,
        updated_at: new Date().toISOString()
    }).eq('id', jobId);

    console.log(`Bulk reply job ${jobId} finished: ${successCount} succeeded, ${failCount} failed`);
}

// ── Get Job Status ───────────────────────────────────────────────────────────

exports.getJobStatus = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { jobId } = req.params;

        const { data: job, error: jobError } = await supabase
            .from('bulk_reply_jobs')
            .select('*')
            .eq('id', jobId)
            .eq('user_id', userId)
            .single();

        if (jobError || !job) {
            return res.status(404).json({ error: 'Job not found' });
        }

        const { data: comments, error: commentsError } = await supabase
            .from('bulk_reply_comments')
            .select('*')
            .eq('job_id', jobId)
            .order('created_at', { ascending: true });

        res.json({
            job,
            comments: comments || [],
            replied_count: (comments || []).filter(c => c.reply_sent).length,
            total_comments: job.total_comments
        });
    } catch (err) {
        console.error('getJobStatus error:', err.message);
        res.status(500).json({ error: 'Failed to get job status', details: err.message });
    }
};

// ── Get All Jobs ─────────────────────────────────────────────────────────────

exports.getJobs = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { platform } = req.query;

        let query = supabase
            .from('bulk_reply_jobs')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', { ascending: false });

        if (platform) {
            query = query.eq('platform', platform);
        }

        const { data: jobs, error } = await query;

        if (error) {
            return res.status(500).json({ error: 'Failed to fetch jobs', details: error.message });
        }

        res.json({ jobs: jobs || [] });
    } catch (err) {
        console.error('getJobs error:', err.message);
        res.status(500).json({ error: 'Failed to fetch jobs', details: err.message });
    }
};

// ── Pause Job ────────────────────────────────────────────────────────────────

exports.pauseJob = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { jobId } = req.params;

        const { data: job, error: findError } = await supabase
            .from('bulk_reply_jobs')
            .select('id, status')
            .eq('id', jobId)
            .eq('user_id', userId)
            .single();

        if (findError || !job) {
            return res.status(404).json({ error: 'Job not found' });
        }

        if (job.status !== 'running') {
            return res.status(400).json({ error: `Cannot pause a job with status "${job.status}"` });
        }

        const { error: updateError } = await supabase
            .from('bulk_reply_jobs')
            .update({ status: 'paused', updated_at: new Date().toISOString() })
            .eq('id', jobId);

        if (updateError) {
            return res.status(500).json({ error: 'Failed to pause job', details: updateError.message });
        }

        res.json({ job_id: jobId, status: 'paused' });
    } catch (err) {
        console.error('pauseJob error:', err.message);
        res.status(500).json({ error: 'Failed to pause job', details: err.message });
    }
};

// ── Resume Job ───────────────────────────────────────────────────────────────

exports.resumeJob = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { jobId } = req.params;

        const { data: job, error: findError } = await supabase
            .from('bulk_reply_jobs')
            .select('id, status')
            .eq('id', jobId)
            .eq('user_id', userId)
            .single();

        if (findError || !job) {
            return res.status(404).json({ error: 'Job not found' });
        }

        if (job.status !== 'paused') {
            return res.status(400).json({ error: `Cannot resume a job with status "${job.status}"` });
        }

        const { error: updateError } = await supabase
            .from('bulk_reply_jobs')
            .update({ status: 'running', updated_at: new Date().toISOString() })
            .eq('id', jobId);

        if (updateError) {
            return res.status(500).json({ error: 'Failed to resume job', details: updateError.message });
        }

        // Re-trigger background processing for remaining comments
        processBulkReply(jobId).catch(err => {
            console.error('Background bulk reply resume error:', err);
        });

        res.json({ job_id: jobId, status: 'running' });
    } catch (err) {
        console.error('resumeJob error:', err.message);
        res.status(500).json({ error: 'Failed to resume job', details: err.message });
    }
};
