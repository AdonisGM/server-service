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
                'https://gomoku.nmtung.dev',
                'http://localhost:5173',
                'https://localhost:5173',
                'http://localhost:9999',
                'https://localhost:9999',
                'http://localhost:5174',
                'https://localhost:5174',
            ]
        }
    });

    io
        .use(async (socket, next) => {
            console.log('io.use() running ...')

            const parseCookie = cookie.parse(socket.handshake.headers.cookie)
            const access_token = parseCookie.access_token

            let username

            if (!access_token) {
                // socket.emit('unauthorized', 'unauthorized');
                // socket.disconnect();
                // return
            }

            try {
                username = getUserInfoByToken(access_token)
            } catch (e) {
                // try to refresh token
                // socket.emit('unauthorized', 'unauthorized');
                // socket.disconnect();
                // return
            }

            socket.data = {
                username: username
            }
            next()
        })
        .on('connection', (socket) => {
            let username = socket.data.username

            if (!username) {
                socket.emit('unauthorized', 'unauthorized');
                socket.disconnect()
                return
            }

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

                    return
                }

                socket.emit('info',  {
                    action: 'createGame',
                    data: {
                        matchId: matchId
                    },
                });

                socket.join(matchId)

                io.to(matchId).emit('logsMatch', `Player ${username} create match!`)

                res = await connectDatabaseService(username, 'pkg_gmk_game.get_all_member', {
                    matchId: matchId
                })

                io.to(matchId).emit('listMember', res)
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

                    return
                }

                socket.emit('info', {
                    action: 'joinGame',
                    data: {
                        matchId: matchId
                    },
                });

                socket.join(matchId)

                io.to(matchId).emit('logsMatch', `Player ${username} join match!`)

                res = await connectDatabaseService(username, 'pkg_gmk_game.get_all_step', {
                    matchId: matchId
                })

                socket.emit('allMove', res)

                res = await connectDatabaseService(username, 'pkg_gmk_game.get_all_member', {
                    matchId: matchId
                })

               io.to(matchId).emit('listMember', res)

                if (res.length !== 2) {
                    return
                }

                res = await connectDatabaseService(username, 'pkg_gmk_game.start_game', {
                    matchId: matchId
                })

                io.to(matchId).emit('info', {
                    action: 'startGame',
                    data: {
                        matchId: matchId
                    },
                });

                res = await connectDatabaseService(username, 'pkg_gmk_game.get_info_game', {
                    matchId: matchId
                })

                io.to(matchId).emit('info', {
                    action: 'infoGame',
                    data: res
                });
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

                res = await connectDatabaseService(username, 'pkg_gmk_game.get_all_step', {
                    matchId: matchId
                })

                io.to(matchId).emit('allMove', res)

                const isWin = checkWinGomoku('TYPE_1', res, {x: locationX, y: locationY, player: username})

                if (isWin) {
                    res = await connectDatabaseService(username, 'pkg_gmk_game.finish_game', {
                        matchId: matchId
                    })
                } else if (res.length === 20 * 20) {
                    res = await connectDatabaseService(username, 'pkg_gmk_game.draw_game', {
                        matchId: matchId
                    })
                }

                res = await connectDatabaseService(username, 'pkg_gmk_game.get_info_game', {
                    matchId: matchId
                })

                io.to(matchId).emit('info', {
                    action: 'infoGame',
                    data: res
                });
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

const checkWinGomoku = (type, steps, lastMove) => {
    let arrSource = []
    let currentPlayer = lastMove.player

    function fnConvertDataToArray () {
        steps.map((step) => {
            return {
                x: step.C_LOCATION_X,
                y: step.C_LOCATION_Y,
                player: step.C_USERNAME,
            }
        }).forEach(step => {
            // check arr source
            if (!arrSource[step.y]) {
                arrSource[step.y] = []
            }

            arrSource[step.y][step.x] = step.player
        })
    }

    function fnGetLocation (x, y) {
        if (!arrSource[y]) {
            return undefined
        }

        if (!arrSource[y][x]) {
            return undefined
        }

        return arrSource[y][x]
    }

    function fnCheckWinVertical () {
        let count = 0
        let index = 0
        while (fnGetLocation(lastMove.x, lastMove.y + index)) {
            const value = fnGetLocation(lastMove.x, lastMove.y + index)

            if (value === currentPlayer) {
                count++;
                index++;
            } else {
                break;
            }
        }

        index = 1
        while (fnGetLocation(lastMove.x, lastMove.y - index)) {
            const value = fnGetLocation(lastMove.x, lastMove.y - index)

            if (value === currentPlayer) {
                count++;
                index++;
            } else {
                break;
            }
        }

        return fnCheckWinType(count)
    }

    function fnCheckWinHorizon () {
        let count = 0
        let index = 0
        while (fnGetLocation(lastMove.x + index, lastMove.y)) {
            const value = fnGetLocation(lastMove.x + index, lastMove.y)

            if (value === currentPlayer) {
                count++;
                index++;
            } else {
                break;
            }
        }

        index = 1
        while (fnGetLocation(lastMove.x - index, lastMove.y)) {
            const value = fnGetLocation(lastMove.x - index, lastMove.y)

            if (value === currentPlayer) {
                count++;
                index++;
            } else {
                break;
            }
        }

        return fnCheckWinType(count)
    }

    function fnCheckWinCross () {
        let count = 0
        let index = 0
        while (fnGetLocation(lastMove.x + index, lastMove.y + index)) {
            const value = fnGetLocation(lastMove.x + index, lastMove.y + index)

            if (value === currentPlayer) {
                count++;
                index++;
            } else {
                break;
            }
        }

        index = 1
        while (fnGetLocation(lastMove.x - index, lastMove.y - index)) {
            const value = fnGetLocation(lastMove.x - index, lastMove.y - index)

            if (value === currentPlayer) {
                count++;
                index++;
            } else {
                break;
            }
        }

        return fnCheckWinType(count)
    }

    function fnCheckWinCrossOr () {
        let count = 0
        let index = 0
        while (fnGetLocation(lastMove.x + index, lastMove.y - index)) {
            const value = fnGetLocation(lastMove.x + index, lastMove.y - index)

            if (value === currentPlayer) {
                count++;
                index++;
            } else {
                break;
            }
        }

        index = 1
        while (fnGetLocation(lastMove.x - index, lastMove.y + index)) {
            const value = fnGetLocation(lastMove.x - index, lastMove.y + index)

            if (value === currentPlayer) {
                count++;
                index++;
            } else {
                break;
            }
        }

        return fnCheckWinType(count)
    }

    function fnCheckWinType (count) {
        if (type === 'TYPE_1' && count === 5) {
            return true
        }

        if (type === 'TYPE_2' && count >= 5) {
            return true
        }

        return false
    }

    fnConvertDataToArray()
    console.table(arrSource)

    let isWin = fnCheckWinVertical()
    if (isWin) {
        console.log(`${currentPlayer} win!!!`)
        return true
    }

    isWin = fnCheckWinHorizon()
    if (isWin) {
        console.log(`${currentPlayer} win!!!`)
        return true
    }

    isWin = fnCheckWinCross()
    if (isWin) {
        console.log(`${currentPlayer} win!!!`)
        return true
    }

    isWin = fnCheckWinCrossOr()
    if (isWin) {
        console.log(`${currentPlayer} win!!!`)
        return true
    }

    return false
}

module.exports = gomokuSocket

