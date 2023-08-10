const express = require('express');
const logger = require('morgan');
const cors = require("cors");
const {json} = require("body-parser");
const oracledb = require("oracledb");
require('dotenv').config()

const adminRouter = require('./routes/admin');
const budgooseRouter = require('./routes/budgoose');

const app = express();

app.use(cors())
app.use(json({limit: '2mb'}))
app.use(logger('dev'));

app.use('/admin', adminRouter);
app.use('/budgoose', budgooseRouter);

async function init() {
  try {
    console.log('Connecting admin ...');
    await oracledb.createPool({
      user          : process.env.DB_ADMIN_USER,
      password      : process.env.DB_ADMIN_PASSWORD,
      connectString : process.env.DB_CONNECT_STRING,
      poolIncrement : 0,
      poolMax       : 4,
      poolMin       : 4,
      poolAlias     : 'admin',
      enableStatistics : true,
    });
    console.log('Connecting budgoose ...');
    await oracledb.createPool({
      user          : process.env.DB_BUDGOOSE_USER,
      password      : process.env.DB_BUDGOOSE_PASSWORD,
      connectString : process.env.DB_CONNECT_STRING,
      poolIncrement : 0,
      poolMax       : 4,
      poolMin       : 4,
      poolAlias     : 'budgoose'
    });
    console.log('Starting server ...');

    const port = process.env.PORT || 5000
    app.listen(port, () => {
      console.log('---=== Server started ===---')
    })
  } catch (err) {
    console.error("start error: " + err.message);
  }
}

init()