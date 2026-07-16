const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middlewares/authMiddleware'); // Need to create this

router.get('/facebook', authController.login);
router.get('/facebook/callback', authController.callback);
router.get('/instagram', authController.loginInstagram);
router.get('/instagram/callback', authController.instagramCallback);
router.get('/me', authMiddleware, authController.getMe);

// Meta data deletion callback (called by Facebook when user removes app)
router.post('/deletion-callback', authController.deletionCallback);

// Manual deletion request (from website form)
router.post('/deletion-request', authController.deletionRequest);

module.exports = router;
