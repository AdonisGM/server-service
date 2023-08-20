const oracledb = require("oracledb");
const jwt = require('jsonwebtoken');

const AuthRouter = (req, res, next) => {
  const access_token = req.signedCookies.access_token;

  if (!access_token) {
    return res.status(401).json({error_message: 'Unauthorized'});
  }

  try {
    const decoded = jwt.verify(access_token, process.env.SECRET_KEY);
    req.dataUser = decoded;
    next();
  } catch (error) {
    return res.status(401).json({error_message: 'Unauthorized'});
  }
}

module.exports = AuthRouter;