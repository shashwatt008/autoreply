const express = require('express');
const router = express.Router();
const automationController = require('../controllers/automationController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/', authMiddleware, automationController.getRules);
router.post('/', authMiddleware, automationController.createRule);
router.put('/:id', authMiddleware, automationController.updateRule);
router.delete('/:id', authMiddleware, automationController.deleteRule);

module.exports = router;
