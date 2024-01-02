const express = require('express');
const logger = require('morgan');
const cors = require("cors");
const {json} = require("body-parser");
const oracledb = require("oracledb");
const cookieParser = require("cookie-parser");
require('dotenv').config()
const cronJobs = require('./controllers/cronJobs');

const authRouter = require('./routes/auth');
const gatewayRouter = require('./routes/gateway');

const app = express();

var subDomain = [
  'https://budgoose.nmtung.dev',
  'https://sso.nmtung.dev',
  'https://admin.nmtung.dev',
  'https://www.nmtung.dev',
  'https://account.nmtung.dev',
  'https://diary.nmtung.dev',
  'http://localhost:5173',
  'https://localhost:5173',
  'http://localhost:5174',
  'https://localhost:5174',
]
var corsOptions = {
  origin: subDomain,
  credentials: true
};
app.use(json({limit: '2mb'}))
app.use(cors(corsOptions))
app.use(logger('dev'));
app.use(cookieParser())

app.use('/account', authRouter);
app.use('/gateway', gatewayRouter);

function init() {
  try {
    oracledb.createPool({
      user          : process.env.DB_ADMIN_USER,
      password      : process.env.DB_ADMIN_PASSWORD,
      connectString : process.env.DB_CONNECT_STRING,
      poolIncrement : 0,
      poolMax       : Number(process.env.DB_POOL_MAX),
      poolMin       : Number(process.env.DB_POOL_MAX),
      poolAlias     : 'admin'
    }).then(() => {
      console.log('Connected to database: Admin');
    }).catch((e) => {
      console.log('Connect fail database: Admin ' + e.message);
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
