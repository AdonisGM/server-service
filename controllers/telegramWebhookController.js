const oracledb = require("oracledb");
const connectDatabase = require("../modal/database");
const connection = require("oracledb/lib/connection");

class GatewayController {
	Index = async (req, res) => {
		const dataUser = req.dataUser;
		const data = req.body;

		const secretTokenTelegram = process.env.SECRET_TOKEN_TELEGRAM;
		const tokenHeader = req.headers['x-telegram-bot-api-secret-token']

		if (secretTokenTelegram !== tokenHeader) {
			console.log('invalid secret token');
			return res.status(401).send({})
		}

		console.log(data);

		let connection
		try {
			oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
			connection = await oracledb.getConnection('admin');

			let resultDb = await connection.execute(
				`
        BEGIN
            PKG_API_TELEGRAM_WEBHOOK.main_api_webhook(:data, :result);
        END;`,
				{
					data: { dir: oracledb.BIND_IN, type: oracledb.CLOB, val: JSON.stringify(data)},
					result: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR, maxSize: 5267}
				}
			);

			let dataRes = await convertResultDbToArray(resultDb);

			if (dataRes.length === 1 && dataRes[0].MESSAGE_ERROR != null) {
				return res.status(200).json({
					error_message: dataRes[0].MESSAGE_ERROR.replace(/ORA-\d{5}: /g, ''),
				});
			}

			return res.json({data: dataRes});
		} catch (error) {
			console.log(`${error.name} - ${error.message}`)
			return res.json({data: ''});
		} finally {
			if (connection) {
				try {
					await connection.close();
				} catch (err) {
					console.error(`${error.name} - ${error.message}`);
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
