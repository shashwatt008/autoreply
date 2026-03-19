const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const { createOrder, verifyPayment, handleWebhook } = require('../controllers/paymentController');

router.post('/create-order', authMiddleware, createOrder);
router.post('/verify', authMiddleware, verifyPayment);
router.post('/webhook', handleWebhook);

module.exports = router;
