const express = require('express');
const logger = require('morgan');
const cors = require("cors");
const {json} = require("body-parser");
const oracledb = require("oracledb");
const cookieParser = require("cookie-parser");
require('dotenv').config()

// const adminRouter = require('./routes/admin');
const authRouter = require('./routes/auth');
// const budgooseRouter = require('./routes/budgoose');

const app = express();

var corsOptions = {
  origin: '*',
  credentials: true,
  exposedHeaders: ["set-cookie"]
};
app.use(cors(corsOptions))
app.use(json({limit: '2mb'}))
app.use(logger('dev'));
app.use(cookieParser())

// app.use('/admin', adminRouter);
app.use('/auth', authRouter);
// app.use('/budgoose', budgooseRouter);

function init() {
  try {
    oracledb.createPool({
      user          : process.env.DB_ADMIN_USER,
      password      : process.env.DB_ADMIN_PASSWORD,
      connectString : process.env.DB_CONNECT_STRING,
      poolIncrement : 0,
      poolMax       : 4,
      poolMin       : 4,
      poolAlias     : 'admin',
      enableStatistics : true,
    }).then(() => {
      console.log('Connected to database: Admin');
    }).catch(() => {
      console.log('Connect fail database: Admin');
    });
    oracledb.createPool({
      user          : process.env.DB_BUDGOOSE_USER,
      password      : process.env.DB_BUDGOOSE_PASSWORD,
      connectString : process.env.DB_CONNECT_STRING,
      poolIncrement : 0,
      poolMax       : 4,
      poolMin       : 4,
      poolAlias     : 'budgoose'
    }).then(() => {
      console.log('Connected to database: Budgoose');
    }).catch(() => {
      console.log('Connect fail database: Budgoose');
    });

    const port = process.env.PORT || 5000
    app.listen(port, () => {
      console.log('---=== Server started ===---')
    })
  } catch (err) {
    console.error("start error: " + err.message);
  }
}

init()