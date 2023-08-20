const oracledb = require("oracledb");
const bcrypt = require("bcrypt");
var jwt = require('jsonwebtoken');

class AuthController {
  Login = async (req, res) => {
    const {username, password} = req.body;
    console.log('Cookies: ', req.signedCookies)
    let connection
    try {
      oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
      connection = await oracledb.getConnection('admin');

      const resultDb = await connection.execute(
        `BEGIN
            pkg_api.main_api(:user, :cmd, :data, :result);
        END;`,
        {
          user: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: 'system'},
          cmd: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: 'pkg_user.get_info_login'},
          data: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: JSON.stringify({username: username})},
          result: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR, maxSize: 4000}
        }
      );

      const resultSet = resultDb.outBinds.result;
      let row;
      let data = [];
      while ((row = await resultSet.getRow())) {
        data.push(row);
      }

      if (data.length == 1 && data[0].MESSAGE_ERROR != null) {
        return res.json({error_message: data[0].MESSAGE_ERROR});
      }

      const isSamePass = await bcrypt.compare(password, data[0].C_PASSWORD)
      if (!(username === data[0].C_USERNAME && isSamePass)) {
        return res.json({error_message: 'Khong hop le'});
      }

      const {token, reToken} = generateToken({username: username}, {username: username});

      return res
        .cookie("access_token", token, {
          httpOnly: false,
          secure: false,
          domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost'
        })
        .cookie("refresh_token", reToken, {
          httpOnly: false,
          secure: false,
          domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost'
        })
        .json({ message: "Logged in successfully 😊 👌" });
    } catch (error) {
      return res.status(400).json({error_message: error + ''});
    }
  }

  SignUp = async (req, res) => {
    const {username, password, fullname, email} = req.body;

    let connection
    try {
      oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
      connection = await oracledb.getConnection('admin');

      const salt = await bcrypt.genSalt(10);
      const hashPassword = await bcrypt.hash(password, salt);

      const resultDb = await connection.execute(
        `BEGIN
            pkg_api.main_api(:user, :cmd, :data, :result);
        END;`,
        {
          user: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: 'system'},
          cmd: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: 'pkg_user.create_user'},
          data: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: JSON.stringify({username: username, password: hashPassword, fullname: fullname, email: email})},
          result: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR, maxSize: 4000}
        }
      );

      const resultSet = resultDb.outBinds.result;
      let row;
      let data = [];
      while ((row = await resultSet.getRow())) {
        data.push(row);
      }

      if (data.length == 1 && data[0].MESSAGE_ERROR != null) {
        return res.json({error_message: data[0].MESSAGE_ERROR});
      }

      return res
        .json({ message: "Sign up successfully 😊 👌" });
    } catch (error) {
      // code 400: bad request
      return res.status(400).json({error_message: error + ''});
    }
  }
}

function generateToken(dataToken, dataRetoken) {
  // exp 30min
  const token = jwt.sign({
    exp: Math.floor(Date.now() / 1000) + (60 * 30),
    data: dataToken,
  }, process.env.SECRET_KEY);
  // exp 7day
  const reToken = jwt.sign({
    exp: Math.floor(Date.now() / 1000) + (60 * 60 * 24 * 7),
    data: dataRetoken,
  }, process.env.SECRET_KEY_RE);

  return {
    token: token,
    reToken: reToken
  }
}

module.exports = new AuthController()
