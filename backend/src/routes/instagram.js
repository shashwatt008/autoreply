const express = require('express');
const router = express.Router();
const instagramController = require('../controllers/instagramController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/', authMiddleware, instagramController.listAccounts);
router.get('/:accountId/media', authMiddleware, instagramController.listMedia);
router.post('/:accountId/media', authMiddleware, instagramController.saveMedia);

module.exports = router;
