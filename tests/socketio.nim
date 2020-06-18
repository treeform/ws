import asyncdispatch, ws

proc socketIo() {.async.} =
    echo "Connecting..."
    # Empty token works to get a reply.
    var webSocket = await newWebSocket("wss://sockets.streamlabs.com/socket.io/?EIO=3&transport=websocket&token=")
    echo "Connected!"
    echo await webSocket.receiveStrPacket()
    echo "Got a packet back!"

waitFor socketIo()