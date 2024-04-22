const schedule = require('node-schedule');
const oracledb = require('oracledb');
const connectDatabase = require("../modal/database");

const abc = schedule.scheduleJob('*/1 * * * * *', function () {
    // getEventPending();
});

const getEventPending = async () => {
    const dataItem = await connectDatabase('pkg_tele_management.get_event', {})

    if (dataItem !== undefined && dataItem !== null && dataItem.length > 0) {
        if (dataItem[0].MESSAGE_ERROR) {
            return;
        }

        const data = {
            method: 'POST',
            body: dataItem[0].C_MESSAGE,
            headers: {
                'Content-Type': 'application/json',
            },
        }

        fetch(`https://api.telegram.org/bot${dataItem[0].TOKEN}/sendMessage`, data)
          .then(res => res.json())
          .then(res => {
              console.log('---- Send notification ----', data);
              console.log(res);
          })
          .catch(err => console.log(err));
    }
}