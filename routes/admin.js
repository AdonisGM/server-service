var express = require('express');
var router = express.Router();
var Main = require('../controllers/userController');

router.get('/', function(req, res, next) {
  res.json({"message": "Welcome to the backend!"});
});
router.post('/admin/gateway', Main.Admin);
router.post('/budgoose/gateway', Main.Budgoose);


module.exports = router;
