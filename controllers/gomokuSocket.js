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

        // Handle create game
        socket.on('createGame', async () => {
            // validate jwt
            try {
                username = getUserInfoByToken(socket.handshake.query.token)
            } catch (e) {
                socket.emit('error', 'unauthorized');
                socket.disconnect();
                return
            }

            // generate ID game
            const nanoid = customAlphabet('1234567890', 6)
            const idGame = nanoid()

            console.log(idGame)

            // add to database
            let res = await connectDatabaseService(username, 'pkg_gmk_game.create_new_game', {
                idGame: idGame
            })

            console.log(res)
        })

        // Handle test emit
        socket.on('test', async () => {
            // validate jwt
            try {
                username = getUserInfoByToken(socket.handshake.query.token)
            } catch (e) {
                socket.emit('error', 'unauthorized');
                socket.disconnect();
                return
            }

            console.log('Test passed !!!')
        })
    });

    io.on('createGame', async (socket) => {
        let username

        // validate jwt
        try {
            username = getUserInfoByToken(socket.handshake.query.token)
        } catch (e) {
            socket.disconnect();
            return
        }

        // generate id
        const nanoid = customAlphabet('1234567890', 6)
        const idGame = nanoid()

        console.log(idGame)

        // add to database
        let res = await connectDatabaseService(username, 'pkg_gmk_game.create_new_game', {
            idGame: idGame
        })

        console.log(res)
    })

    io.on('joinGame', (socket) => {
        // validate jwt
        try {
            username = getUserInfoByToken(socket.handshake.query.token)
        } catch (e) {
            socket.disconnect();
            return
        }

    })

    io.on('play', (socket) => {
        // validate jwt
        try {
            username = getUserInfoByToken(socket.handshake.query.token)
        } catch (e) {
            socket.disconnect();
            return
        }
    })

    io.on('test', (socket) => {
        // validate jwt
        console.log('test');
        socket.emit('test', 'test');
    })
}

function getUserInfoByToken (token) {
    const decoded = verify(token, process.env.SECRET_KEY);
    return decoded.data.username
}

module.exports = gomokuSocket

