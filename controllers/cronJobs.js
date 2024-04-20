const schedule = require('node-schedule');
const oracledb = require('oracledb');
const connectDatabase = require("../modal/database");

// run every 1 hour
const job = schedule.scheduleJob('0 0 * * * *', function () {
    callApiDb();
});

const abc = schedule.scheduleJob('*/2 * * * * *', function () {
    getEventPending();
});

const callApiDb = async () => {
    const dataUser = 'autobot';
    const cmd = 'pkg_auto_bot.auto_bot';
    const data = {};

    let connection;
    try {
        oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
        connection = await oracledb.getConnection('admin');

        let resultDb = await connection.execute(
            `
        BEGIN
            pkg_api.main_api(:user, :cmd, :data, :result);
        END;`,
            {
                user: {
                    dir: oracledb.BIND_IN,
                    type: oracledb.STRING,
                    val: dataUser,
                },
                cmd: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: cmd },
                data: {
                    dir: oracledb.BIND_IN,
                    type: oracledb.CLOB,
                    val: JSON.stringify(data),
                },
                result: {
                    dir: oracledb.BIND_OUT,
                    type: oracledb.CURSOR,
                    maxSize: 5267,
                },
            }
        );

        let dataRes = await convertResultDbToArray(resultDb);

        if (dataRes.length === 1 && dataRes[0].MESSAGE_ERROR != null) {
            return res.status(400).json({
                error_message: dataRes[0].MESSAGE_ERROR.replace(
                    /ORA-\d{5}: /g,
                    ''
                ),
            });
        }

        console.log('callApiDb success');
    } catch (error) {
        console.log('callApiDb error: ' + error.message);
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error(err.message);
            }
        }
    }
};

const getEventPending = async () => {
    console.log('--- getEventPending ---')

    const dataItem = await connectDatabase('pkg_tele_management.get_event', {})
    console.log(dataItem)

    if (dataItem !== undefined && dataItem !== null && dataItem.length > 0) {
        fetch(`https://api.telegram.org/bot${dataItem[0].TOKEN}/sendMessage`, {
            method: 'POST',
            body: JSON.parse(dataItem[0].C_MESSAGE),
        })
          .then(res => res.json())
          .then(data => {
              console.log(data)
          })
          .catch(err => console.log(err));
    }
}

const convertResultDbToArray = async (resultDb) => {
    let data = [];
    let row;
    while ((row = await resultDb.outBinds.result.getRow())) {
        data.push(row);
    }
    return data;
};
