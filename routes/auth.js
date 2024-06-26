const express = require('express');
const router = express.Router();
const AuthController = require('../controllers/authController');
const AuthRouter = require('../middleware/authRouter');

router.post('/login', AuthController.Login);
router.post('/sign-up', AuthController.SignUp);
router.post('/refresh-token', AuthController.RefreshToken);
router.post('/logout', AuthController.Logout);

module.exports = router;
