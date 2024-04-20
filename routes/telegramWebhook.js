const express = require('express');
const router = express.Router();
const TelegramWebhookController = require('../controllers/telegramWebhookController');

router.post('/', TelegramWebhookController.Index);

module.exports = router;
