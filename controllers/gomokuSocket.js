const { Server } = require('socket.io');
const {verify} = require("jsonwebtoken");

const {customAlphabet} = require("nanoid");
const connectDatabaseService = require("../modal/database");

function gomokuSocket (server) {
    const io = new Server(server);

    io.on('connection', (socket) => {
        let username

        // Handle user disconnected
        socket.on('disconnect', () => {
            console.log('user disconnected');
        });

        // Handle create game action
        socket.on('createGame', async () => {
            // validate jwt
            try {
                username = getUserInfoByToken(socket.handshake.query.token)
            } catch (e) {
                socket.emit('unauthorized', 'unauthorized');
                socket.disconnect();
                return
            }

            // generate ID game
            const nanoid = customAlphabet('1234567890abcdef', 16)
            const matchId = nanoid()

            // add to database
            let res = await connectDatabaseService(username, 'pkg_gmk_game.create_new_game', {
                matchId: matchId
            })

            if (res.length === 1 && res[0].MESSAGE_ERROR != null) {
                socket.emit('error', {
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
            // validate jwt
            try {
                username = getUserInfoByToken(socket.handshake.query.token)
            } catch (e) {
                socket.emit('unauthorized', 'unauthorized');
                socket.disconnect();
                return
            }

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

            // validate jwt
            try {
                username = getUserInfoByToken(socket.handshake.query.token)
            } catch (e) {
                socket.emit('unauthorized', 'unauthorized');
                socket.disconnect();
                return
            }

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

            // validate jwt
            try {
                username = getUserInfoByToken(socket.handshake.query.token)
            } catch (e) {
                socket.emit('unauthorized', 'unauthorized');
                socket.disconnect();
                return
            }

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

            // validate jwt
            try {
                username = getUserInfoByToken(socket.handshake.query.token)
            } catch (e) {
                socket.emit('unauthorized', 'unauthorized');
                socket.disconnect();
                return
            }

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

module.exports = gomokuSocket

