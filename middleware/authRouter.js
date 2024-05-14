const jwt = require('jsonwebtoken');

const AuthRouter = (req, res, next) => {
  const access_token = req.cookies.access_token;

  if (!access_token) {
    return res
      .status(401)
      .clearCookie("access_token", {
        httpOnly: true,
        secure: true,
        domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost',
        sameSite: process.env.ENVIRONMENT === 'production' ? 'lax' : 'none'
      })
      .clearCookie("info", {
        httpOnly: false,
        secure: true,
        domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost',
        sameSite: process.env.ENVIRONMENT === 'production' ? 'lax' : 'none'
      })
      .json({error_message: 'Unauthorized'});
  }

  try {
    const decoded = jwt.verify(access_token, process.env.SECRET_KEY);
    console.log(decoded)
    req.dataUser = decoded.data;
    next();
  } catch (error) {
    console.log(error)
    return res
      .status(401)
      .clearCookie("access_token", {
        httpOnly: true,
        secure: true,
        domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost',
        sameSite: process.env.ENVIRONMENT === 'production' ? 'lax' : 'none'
      })
      .clearCookie("info", {
        httpOnly: false,
        secure: true,
        domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost',
        sameSite: process.env.ENVIRONMENT === 'production' ? 'lax' : 'none'
      })
      .json({error_message: 'Unauthorized'});
  }
}

module.exports = AuthRouter;