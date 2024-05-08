const schedule = require('node-schedule');
const oracledb = require('oracledb');
const connectDatabase = require("../modal/database");

const abc = schedule.scheduleJob('*/1 * * * * *', function () {
    getEventPending(); 
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

        fetch(`https://api.telegram.org/bot${dataItem[0].TOKEN}${dataItem[0].C_METHOD}`, data)
          .then(res => res.json())
          .then(res => {
              console.log('---- Send notification ----', data);
              console.log(res);
              try {
                  const dataItem = await connectDatabase('pkg_tele_management.update_event', {
                      pk_event: dataItem[0].PK_TELE_SEND_MESSAGE,
                      res: JSON.stringfy(res)
                  })
              } catch (error) {
                  console.log(error)
              }
          })
          .catch(err => {
              console.log(err)
              const dataItem = await connectDatabase('pkg_tele_management.update_event', {
                  pk_event: dataItem[0].PK_TELE_SEND_MESSAGE,
                  res: JSON.stringfy(err)
              })
          });
    }
}
