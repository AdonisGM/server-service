const oracledb = require("oracledb");

const connectDatabase = async (cmd, data) => {
	let connection
	try {
		oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
		connection = await oracledb.getConnection('admin');

		let resultDb = await connection.execute(
			`
			BEGIN
				pkg_api_server.main_api(:user, :cmd, :data);
			END;`,
			{
				user: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: undefined},
				cmd: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: cmd},
				data: { dir: oracledb.BIND_IN, type: oracledb.CLOB, val: JSON.stringify(data)},
			}
		);

		return convertResultDbToArray(resultDb);
	} catch (error) {
		console.log('error', error.message);
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

const convertResultDbToArray = (resultDb) => {
	if (!resultDb.implicitResults) {
		return []
	}

	return resultDb.implicitResults[0];
}

module.exports = connectDatabase