const express = require('express');
const router = express.Router();
const postController = require('../controllers/postController');
const authMiddleware = require('../middlewares/authMiddleware');

// Get posts for a specific page
router.get('/:pageId/posts', authMiddleware, postController.listPosts);

// Save a selected post
router.post('/:pageId/posts', authMiddleware, postController.savePost);

module.exports = router;
