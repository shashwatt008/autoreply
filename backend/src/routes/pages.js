const express = require('express');
const router = express.Router();
const pageController = require('../controllers/pageController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/', authMiddleware, pageController.listPages);
// router.post('/sync', authMiddleware, pageController.syncPages); // If we want manual sync

module.exports = router;
