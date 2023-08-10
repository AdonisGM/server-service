const oracledb = require("oracledb");
const bcrypt = require("bcrypt");
var jwt = require('jsonwebtoken');

class AuthController {
  Login = async (req, res) => {
    const {username, password} = req.body;

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
        throw new Error(data[0].MESSAGE_ERROR);
      }
      
      const isSamePass = await bcrypt.compare(password, data[0].C_PASSWORD)
      if (!(username == data[0].C_USERNAME && isSamePass)) {
        return res.json({error_message: 'Khong hop le'});
      }

      const token = jwt.sign({
        exp: Math.floor(Date.now() / 1000) + (60 * 60),
        data: {
          username: username
        },
      }, process.env.SECRET_KEY);
      const reToken = jwt.sign({
        exp: Math.floor(Date.now() / 1000) + (60 * 60),
        data: {
          username: username
        },
      }, process.env.SECRET_KEY_RE);

      return res
        .cookie("access_token", token, {
          httpOnly: true,
          secure: false,
          domain: '.nmtung.dev'
        })
        .cookie("refresh_token", reToken, {
          httpOnly: true,
          secure: false,
          domain: '.nmtung.dev'
        })
        
        .json({ message: "Logged in successfully 😊 👌" });
    } catch (error) {
      return res.json({error_message: error + ''});
    }
  }
}

module.exports = new AuthController()