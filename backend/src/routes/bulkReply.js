const express = require('express');
const router = express.Router();
const bulkReplyController = require('../controllers/bulkReplyController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/comments/:postId', authMiddleware, bulkReplyController.fetchComments);
router.post('/start', authMiddleware, bulkReplyController.startBulkReply);
router.get('/jobs', authMiddleware, bulkReplyController.getJobs);
router.get('/jobs/:jobId', authMiddleware, bulkReplyController.getJobStatus);
router.put('/jobs/:jobId/pause', authMiddleware, bulkReplyController.pauseJob);
router.put('/jobs/:jobId/resume', authMiddleware, bulkReplyController.resumeJob);

module.exports = router;
