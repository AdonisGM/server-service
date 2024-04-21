const oracledb = require("oracledb");

const connectDatabase = async (cmd, data) => {
	const dataUser = '';

	let connection
	try {
		oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
		connection = await oracledb.getConnection('admin');
		console.log('oracledb.getConnection(\'admin\');')

		let resultDb = await connection.execute(
			`
        BEGIN
            pkg_api_public.main_api(:user, :cmd, :data, :result);
        END;`,
			{
				user: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: dataUser.username},
				cmd: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: cmd},
				data: { dir: oracledb.BIND_IN, type: oracledb.CLOB, val: JSON.stringify(data)},
				result: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR, maxSize: 5267}
			}
		);

		console.log('connection', connection)
		let dataRes = await convertResultDbToArray(resultDb);
		console.log('connection-1', connection)
		if (connection) {
			try {
				await connection.close();
				console.log('connection.close();')
			} catch (err) {
				console.log('connection.close() - ERROR;')
				console.error(err.message);
			}
		}

		if (dataRes.length === 1 && dataRes[0].MESSAGE_ERROR != null) {
			return res.status(400).json({
				error_message: dataRes[0].MESSAGE_ERROR.replace(/ORA-\d{5}: /g, ''),
			});
		}

		return dataRes;
	} catch (error) {
		console.log('error', error)
	} finally {
		console.log('finally', connection)
		if (connection) {
			try {
				await connection.close();
				console.log('finally, close')
			} catch (err) {
				console.error(err.message);
			}
		}
	}
}

const convertResultDbToArray = async (resultDb) => {
	let data = [];
	let row;
	while ((row = await resultDb.outBinds.result.getRow())) {
		data.push(row);
	}
	return data;
}

module.exports = connectDatabase