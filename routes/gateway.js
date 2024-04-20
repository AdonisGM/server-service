const express = require('express');
const router = express.Router();
const GatewayController = require('../controllers/gatewayController');
const AuthRouter = require('../middleware/authRouter');

router.post('/', AuthRouter, GatewayController.Index);
router.post('/public', GatewayController.Public);

module.exports = router;
