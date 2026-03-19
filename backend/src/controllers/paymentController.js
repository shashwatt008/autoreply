const Razorpay = require('razorpay');
const crypto = require('crypto');
const supabase = require('../config/supabase');

let razorpay = null;
if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
    razorpay = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET
    });
} else {
    console.warn('⚠️ Razorpay keys not set. Payment features will be disabled.');
}

const PLAN_AMOUNT = 99900; // ₹999 in paise
const PLAN_CURRENCY = 'INR';

// POST /create-order — creates a Razorpay order
const createOrder = async (req, res) => {
    if (!razorpay) return res.status(503).json({ error: 'Payment service not configured' });
    try {
        const userId = req.user.userId;

        const order = await razorpay.orders.create({
            amount: PLAN_AMOUNT,
            currency: PLAN_CURRENCY,
            receipt: `pro_${userId}_${Date.now()}`,
            notes: {
                userId,
                plan: 'pro'
            }
        });

        res.json({
            success: true,
            order_id: order.id,
            amount: order.amount,
            currency: order.currency,
            key_id: process.env.RAZORPAY_KEY_ID
        });
    } catch (err) {
        console.error('Razorpay create order error:', err);
        res.status(500).json({ error: 'Failed to create payment order' });
    }
};

// POST /verify — verifies Razorpay payment signature and upgrades user
const verifyPayment = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

        if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
            return res.status(400).json({ error: 'Missing payment details' });
        }

        // Verify signature
        const expectedSignature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
            .update(`${razorpay_order_id}|${razorpay_payment_id}`)
            .digest('hex');

        if (expectedSignature !== razorpay_signature) {
            return res.status(400).json({ error: 'Invalid payment signature' });
        }

        // Upgrade user to Pro
        const { error } = await supabase
            .from('users')
            .update({
                subscription_plan: 'pro',
                reply_limit: 1000000
            })
            .eq('id', userId);

        if (error) {
            console.error('Supabase update error:', error);
            return res.status(500).json({ error: 'Payment verified but failed to upgrade account' });
        }

        res.json({
            success: true,
            message: 'Payment verified. Account upgraded to Pro.'
        });
    } catch (err) {
        console.error('Payment verification error:', err);
        res.status(500).json({ error: 'Payment verification failed' });
    }
};

// POST /webhook — Razorpay webhook handler (no auth)
const handleWebhook = async (req, res) => {
    try {
        const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
        const receivedSignature = req.headers['x-razorpay-signature'];

        if (!receivedSignature) {
            return res.status(400).json({ error: 'Missing webhook signature' });
        }

        // Verify webhook signature
        const expectedSignature = crypto
            .createHmac('sha256', webhookSecret)
            .update(JSON.stringify(req.body))
            .digest('hex');

        if (expectedSignature !== receivedSignature) {
            return res.status(400).json({ error: 'Invalid webhook signature' });
        }

        const event = req.body.event;
        const payload = req.body.payload;

        if (event === 'payment.captured') {
            const payment = payload.payment.entity;
            const orderId = payment.order_id;

            // Fetch order to get userId from notes
            const order = await razorpay.orders.fetch(orderId);
            const userId = order.notes?.userId;

            if (userId) {
                const { error } = await supabase
                    .from('users')
                    .update({
                        subscription_plan: 'pro',
                        reply_limit: 1000000
                    })
                    .eq('id', userId);

                if (error) {
                    console.error('Webhook: Supabase update error:', error);
                }
            }
        }

        // Always return 200 to acknowledge receipt
        res.json({ status: 'ok' });
    } catch (err) {
        console.error('Webhook processing error:', err);
        // Still return 200 to prevent Razorpay retries on processing errors
        res.json({ status: 'ok' });
    }
};

module.exports = { createOrder, verifyPayment, handleWebhook };
