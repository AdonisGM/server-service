const oracledb = require("oracledb");

class GatewayController {
	Index = async (req, res) => {
		const dataUser = req.dataUser;
		const data = req.body;

		let connection
		try {
			oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
			connection = await oracledb.getConnection('admin');

			let resultDb = await connection.execute(
				`
        BEGIN
            PKG_API_TELEGRAM_WEBHOOK.main_api_webhook(:data);
        END;`,
				{
					data: { dir: oracledb.BIND_IN, type: oracledb.CLOB, val: JSON.stringify(data)}
				}
			);

			return res.json({data: ''});
		} catch (error) {
			console.log(error)
			return res.json({data: ''});
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

const convertResultDbToArray = async (resultDb) => {
	let data = [];
	let row;
	while ((row = await resultDb.outBinds.result.getRow())) {
		data.push(row);
	}
	return data;
}

module.exports = new GatewayController();