const oracledb = require("oracledb");

class GatewayController {
  Index = async (req, res) => {
    const dataUser = req.dataUser;
    const {cmd, data} = req.body;

    let connection
    try {
      oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
	  oracledb.fetchAsString = [ oracledb.CLOB ];
      connection = await oracledb.getConnection('admin');

      let resultDb = await connection.execute(
        `
        BEGIN
            pkg_api.main_api(:user, :cmd, :data);
        END;`,
        {
          user: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: dataUser.username},
          cmd: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: cmd},
          data: { dir: oracledb.BIND_IN, type: oracledb.CLOB, val: JSON.stringify(data)}
        }
      );
      
      let dataRes = convertResultDbToArray(resultDb);
      console.log(dataRes)
      if (dataRes.length === 1 && dataRes[0].MESSAGE_ERROR != null) {
        return res.status(400).json({
          error_message: dataRes[0].MESSAGE_ERROR.replace(/ORA-\d{5}: /g, ''),
        });
      }

      return res.json({data: dataRes});
    } catch (error) {
	  console.error(err.message); 
      return res.json({error_message: error.message});
    } finally {
      if (connection) {
        try {
          await connection.close();
        } catch (err) {
          console.error(err.message);
        }
      }
    }
  }
}

const convertResultDbToArray = (resultDb) => {
  if (!resultDb.implicitResults) {
    return []
  }

  return resultDb.implicitResults[0];
}

module.exports = new GatewayController();