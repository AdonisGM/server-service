const { Server } = require('socket.io');
const {verify} = require("jsonwebtoken");
const cookie = require('cookie');

const {customAlphabet} = require("nanoid");
const connectDatabaseService = require("../modal/database");
const oracledb = require("oracledb");
const jwt = require("jsonwebtoken");

function gomokuSocket (server) {
    const io = new Server(server, {
        cors: {
            origin: [
                'https://budgoose.nmtung.dev',
                'https://sso.nmtung.dev',
                'https://admin.nmtung.dev',
                'https://www.nmtung.dev',
                'https://account.nmtung.dev',
                'https://diary.nmtung.dev',
                'http://localhost:5173',
                'https://localhost:5173',
                'http://localhost:9999',
                'https://localhost:9999',
                'http://localhost:5174',
                'https://localhost:5174',
            ]
        }
    });

    io.engine.on("initial_headers", async (headers, req) => {
        const parseCookie = cookie.parse(req.headers.cookie)
        const refresh_token = parseCookie.refresh_token
        const data = await refreshToken(refresh_token)

        if (data) {
            const cookieAccessToken = cookie.serialize('access_token', data.token, {
                httpOnly: true,
                secure: true,
                domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost',
                sameSite: process.env.ENVIRONMENT === 'production' ? 'lax' : 'none'
            })
            const cookieRefreshToken = cookie.serialize('refresh_token', data.reToken, {
                httpOnly: true,
                secure: true,
                domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost',
                sameSite: process.env.ENVIRONMENT === 'production' ? 'lax' : 'none'
            })
            const cookieInfo = cookie.serialize('info', data.dataUser.username, {
                httpOnly: true,
                secure: true,
                domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost',
                sameSite: process.env.ENVIRONMENT === 'production' ? 'lax' : 'none'
            })

            headers['set-cookie'] = cookieAccessToken
            /**
             * .cookie("access_token", token, {
             *           httpOnly: true,
             *           secure: true,
             *           domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost',
             *           sameSite: process.env.ENVIRONMENT === 'production' ? 'lax' : 'none'
             *         })
             *         .cookie("refresh_token", reToken, {
             *           httpOnly: true,
             *           secure: true,
             *           domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost',
             *           sameSite: process.env.ENVIRONMENT === 'production' ? 'lax' : 'none'
             *         })
             *         .cookie("info", dataUser.username, {
             *           httpOnly: false,
             *           secure: true,
             *           domain: process.env.ENVIRONMENT === 'production' ? '.nmtung.dev' : 'localhost',
             *           sameSite: process.env.ENVIRONMENT === 'production' ? 'lax' : 'none'
             *         })
             */
        } else {

        }
    });

    io
        .use(async (socket, next) => {
            const parseCookie = cookie.parse(socket.handshake.headers.cookie)
            const access_token = parseCookie.access_token

            let username

            if (!access_token || !refresh_token) {
                socket.emit('unauthorized', 'unauthorized');
                socket.disconnect();
                return
            }

            try {
                username = getUserInfoByToken(access_token)
            } catch (e) {
                // try to refresh token
                socket.emit('unauthorized', 'unauthorized');
                socket.disconnect();
                return
            }

            socket.data = {
                username: username
            }
            next()
        })
        .on('connection', (socket) => {
            let username = socket.data.username

            // Handle user disconnected
            socket.on('disconnect', () => {
                console.log('user disconnected');
            });

            // Handle create game action
            socket.on('createGame', async () => {
                // generate ID game
                const nanoid = customAlphabet('1234567890abcdef', 16)
                const matchId = nanoid()

                // add to database
                let res = await connectDatabaseService(username, 'pkg_gmk_game.create_new_game', {
                    matchId: matchId
                })

                if (res.length === 1 && res[0].MESSAGE_ERROR != null) {
                    socket.emit('error', {
                        error_code: -99,
                        error_message: res[0].MESSAGE_ERROR.replace(/ORA-\d{5}: /g, ''),
                    });
                }

                if (res.length === 0) {
                    socket.emit('info', {
                        action: 'createGame',
                        data: {
                            matchId: matchId
                        },
                    });

                    socket.join(matchId)

                    io.to(matchId).emit('logsMatch', `Player ${username} create match!`)
                }
            })

            // Handle join game action
            socket.on('joinGame', async (dataMessage) => {
                let matchId = dataMessage.matchId

                // add to database
                let res = await connectDatabaseService(username, 'pkg_gmk_game.join_game', {
                    matchId: matchId
                })

                if (res.length === 1 && res[0].MESSAGE_ERROR != null) {
                    socket.emit('error', {
                        error_code: -99,
                        error_message: res[0].MESSAGE_ERROR.replace(/ORA-\d{5}: /g, ''),
                    });
                }

                if (res.length === 0) {
                    socket.emit('info', {
                        action: 'joinGame',
                        data: {
                            matchId: matchId
                        },
                    });

                    socket.join(matchId)

                    io.to(matchId).emit('logsMatch', `Player ${username} join match!`)

                    let res = await connectDatabaseService(username, 'pkg_gmk_game.get_all_step', {
                        matchId: matchId
                    })

                    socket.emit('allMove', res)
                }
            })

            // Handle move action
            socket.on('startGame', async (dataMessage) => {
                let matchId = dataMessage.matchId

                // add to database
                let res = await connectDatabaseService(username, 'pkg_gmk_game.start_game', {
                    matchId: matchId,
                })

                if (res.length === 1 && res[0].MESSAGE_ERROR != null) {
                    socket.emit('error', {
                        error_code: -99,
                        error_message: res[0].MESSAGE_ERROR.replace(/ORA-\d{5}: /g, ''),
                    });
                    return;
                }

                io.to(matchId).emit('info', {
                    action: 'startGame',
                    data: {
                        matchId: matchId
                    },
                });
            })

            // Handle move action
            socket.on('move', async (dataMessage) => {
                let matchId = dataMessage.matchId
                let locationX = dataMessage.locationX
                let locationY = dataMessage.locationY

                // add to database
                let res = await connectDatabaseService(username, 'pkg_gmk_game.add_step', {
                    matchId: matchId,
                    locationX: locationX,
                    locationY: locationY
                })

                if (res.length === 1 && res[0].MESSAGE_ERROR != null) {
                    socket.emit('error', {
                        error_code: -99,
                        error_message: res[0].MESSAGE_ERROR.replace(/ORA-\d{5}: /g, ''),
                    });
                    return;
                }

                io.to(matchId).emit('move', res)
            })

            // Handle test emit
            socket.on('test', async (dataMessage) => {
                let matchId = dataMessage.matchId

                io.to(matchId).emit('info', {
                    action: 'aaaaaaaaaaaaaaaaaaaaa',
                    data: {
                        matchId: matchId
                    },
                });
            })
        });
}

function getUserInfoByToken (token) {
    const decoded = verify(token, process.env.SECRET_KEY);
    return decoded.data.username
}

async function refreshToken (refresh_token) {
    let connection
    try {
        oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
        connection = await oracledb.getConnection('admin');

        let resultDb = await connection.execute(
            `BEGIN
            pkg_api.main_api(:user, :cmd, :data);
        END;`,
            {
                user: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: 'system'},
                cmd: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: 'pkg_user.get_refresh_token'},
                data: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: JSON.stringify({refreshToken: refresh_token})}
            }
        );

        let data = await convertResultDbToArray(resultDb);

        if (data.length === 1 && data[0].MESSAGE_ERROR != null) {
            return null;
        }

        const dataUser = {
            username: data[0].C_USERNAME
        }
        const {token, reToken} = generateToken(dataUser, dataUser);

        resultDb = await connection.execute(
            `BEGIN
            pkg_api.main_api(:user, :cmd, :data);
        END;`,
            {
                user: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: data[0].C_USERNAME},
                cmd: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: 'pkg_user.create_refresh_token'},
                data: { dir: oracledb.BIND_IN, type: oracledb.STRING, val: JSON.stringify({refreshToken: reToken, refreshTokenOld: refresh_token})}
            }
        );

        data = await convertResultDbToArray(resultDb);

        if (data.length === 1 && data[0].MESSAGE_ERROR != null) {
            return null;
        }

        return {
            token, reToken, dataUser
        }
    } catch (error) {
        return null;
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error(err);
            }
        }
    }
}

function convertResultDbToArray(resultDb) {
    if (!resultDb.implicitResults) {
        return []
    }

    return resultDb.implicitResults[0];
}

function generateToken(dataToken, dataRetoken) {
    console.log(dataToken, dataRetoken)

    // exp 30min
    const token = jwt.sign({
        exp: Math.floor(Date.now() / 1000) + (60 * 10),
        data: dataToken,
    }, process.env.SECRET_KEY);
    // exp 7day
    const reToken = jwt.sign({
        exp: Math.floor(Date.now() / 1000) + (60 * 60 * 24 * 7),
        data: dataRetoken,
    }, process.env.SECRET_KEY_RE);

    return {
        token: token,
        reToken: reToken
    }
}

module.exports = gomokuSocket

