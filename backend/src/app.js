const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const authRoutes = require('./routes/auth');
const pageRoutes = require('./routes/pages');
const postRoutes = require('./routes/posts');
const automationRoutes = require('./routes/automation');
const paymentRoutes = require('./routes/payment');
const webhookRoutes = require('./routes/webhook');
const instagramRoutes = require('./routes/instagram');
const bulkReplyRoutes = require('./routes/bulkReply');

const app = express();

// CORS
const allowedOrigins = [
    process.env.FRONTEND_URL,
    'https://autoreply-io.web.app',
    'http://localhost:3000',
    'http://localhost:3001'
].filter(Boolean);
app.use(cors({
    origin: (origin, callback) => {
        if (!origin || allowedOrigins.includes(origin)) {
            callback(null, true);
        } else if (process.env.NODE_ENV !== 'production') {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true
}));

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Routes
app.get('/', (req, res) => {
    res.json({ status: 'ok', message: 'AutoReply.io API Running' });
});

app.use('/auth', authRoutes);
app.use('/pages', pageRoutes);
app.use('/posts', postRoutes);
app.use('/automation', automationRoutes);
app.use('/payment', paymentRoutes);
app.use('/webhook', webhookRoutes);
app.use('/instagram', instagramRoutes);
app.use('/bulk-reply', bulkReplyRoutes);

module.exports = app;
