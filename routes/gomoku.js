const express = require('express');
const router = express.Router();
const GomokuController = require('../controllers/gomokuController');
const AuthRouter = require('../middleware/authRouter');

router.post('/create-new-game', AuthRouter, GomokuController.CreateNewGame);

module.exports = router;
