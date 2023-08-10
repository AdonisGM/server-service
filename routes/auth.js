var express = require('express');
var router = express.Router();
var AuthController = require('../controllers/authController');

router.post('/login', AuthController.Login);
router.post('/sign-up', AuthController.SignUp);

module.exports = router;
