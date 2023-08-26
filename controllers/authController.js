const oracledb = require("oracledb");
const bcrypt = require("bcrypt");
const jwt = require('jsonwebtoken');

class AuthController {
  Login = async (req, res) => {
    const {username, password} = req.body;
    let connection
    try {
      oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
      connection = await oracledb.getConnection('admin');

      let resultDb = await connection.execute(
        `BEGIN
            pkg_api.main_api(:user, :cmd, :data, :result);
        END;`,
        {
          user: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: username},
          cmd: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: 'pkg_user.get_info_login'},
          data: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: JSON.stringify({username: username})},
          result: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR, maxSize: 4000}
        }
      );

      let data = await convertResultDbToArray(resultDb);

      if (data.length === 1 && data[0].MESSAGE_ERROR != null) {
        return res.json({error_message: data[0].MESSAGE_ERROR});
      }

      const isSamePass = await bcrypt.compare(password, data[0].C_PASSWORD)
      if (!(username === data[0].C_USERNAME && isSamePass)) {
        return res.json({error_message: 'Khong hop le'});
      }

      const {token, reToken} = generateToken({username: username}, {username: username});

      resultDb = await connection.execute(
        `BEGIN
            pkg_api.main_api(:user, :cmd, :data, :result);
        END;`,
        {
          user: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: username},
          cmd: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: 'pkg_user.create_refresh_token'},
          data: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: JSON.stringify({refreshToken: reToken, refreshTokenOld: ''})},
          result: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR, maxSize: 4000}
        }
      );

      data = await convertResultDbToArray(resultDb);

      if (data.length === 1 && data[0].MESSAGE_ERROR != null) {
        return res.json({error_message: data[0].MESSAGE_ERROR});
      }

      return res
        .cookie("access_token", token, {
          httpOnly: false,
          secure: true,
          domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost'
        })
        .cookie("refresh_token", reToken, {
          httpOnly: false,
          secure: true,
          domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost'
        })
        .json({ message: "Logged in successfully 😊 👌" });
    } catch (error) {
      return res.status(400).json({error_message: error + '123'});
    } finally {
      if (connection) {
        try {
          await connection.close();
        } catch (err) {
          console.error(err);
        }
      }
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

      const data = await convertResultDbToArray(resultDb);

      if (data.length === 1 && data[0].MESSAGE_ERROR != null) {
        return res.json({error_message: data[0].MESSAGE_ERROR});
      }

      return res
        .json({ message: "Sign up successfully 😊 👌" });
    } catch (error) {
      // code 400: bad request
      return res.status(400).json({error_message: error + ''});
    } finally {
      if (connection) {
        try {
          await connection.close();
        } catch (err) {
          console.error(err);
        }
      }
    }
  }

  RefreshToken = async (req, res) => {
    const refresh_token = req.cookies.refresh_token;

    let connection
    try {
      oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
      connection = await oracledb.getConnection('admin');

      let resultDb = await connection.execute(
        `BEGIN
            pkg_api.main_api(:user, :cmd, :data, :result);
        END;`,
        {
          user: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: 'system'},
          cmd: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: 'pkg_user.get_refresh_token'},
          data: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: JSON.stringify({refreshToken: refresh_token})},
          result: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR, maxSize: 4000}
        }
      );

      let data = await convertResultDbToArray(resultDb);

      if (data.length === 1 && data[0].MESSAGE_ERROR != null) {
        return res.status(401).json({error_message: data[0].MESSAGE_ERROR});
      }

      const dataUser = {
        username: data[0].C_USERNAME
      }
      const {token, reToken} = generateToken(dataUser, dataUser);

      resultDb = await connection.execute(
        `BEGIN
            pkg_api.main_api(:user, :cmd, :data, :result);
        END;`,
        {
          user: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: data[0].C_USERNAME},
          cmd: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: 'pkg_user.create_refresh_token'},
          data: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: JSON.stringify({refreshToken: reToken, refreshTokenOld: refresh_token})},
          result: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR, maxSize: 4000}
        }
      );

      data = await convertResultDbToArray(resultDb);

      if (data.length === 1 && data[0].MESSAGE_ERROR != null) {
        return res.status(401).json({error_message: data[0].MESSAGE_ERROR});
      }

      return res
        .cookie("access_token", token, {
          httpOnly: false,
          secure: true,
          domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost'
        })
        .cookie("refresh_token", reToken, {
          httpOnly: false,
          secure: true,
          domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost'
        })
        .json({ message: "Refresh token successfully" });
    } catch (error) {
      return res.status(401).json({error_message: error + ''});
    } finally {
      if (connection) {
        try {
          await connection.close();
        } catch (err) {
          console.error(err);
        }
      }
    }
  }
}

async function convertResultDbToArray(resultDb) {
  const resultSet = resultDb.outBinds.result;
  let row;
  let data = [];
  while ((row = await resultSet.getRow())) {
    data.push(row);
  }

  return data;
}

function generateToken(dataToken, dataRetoken) {
  console.log(dataToken, dataRetoken)

  // exp 30min
  const token = jwt.sign({
    exp: Math.floor(Date.now() / 1000) + (60 * 10),
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
