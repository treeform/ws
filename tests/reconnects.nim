import ws, asyncdispatch, strutils

var socket: WebSocket

proc newConnection() =
  echo "Connecting..."
  socket = waitFor newWebSocket("ws://localhost:9001")
  socket.setupPings(15)

proc getMessage() =
  try:
    echo "Got message: ", waitFor socket.receiveStrPacket()
  except WebSocketError:
    echo "WebSocketError!"
    newConnection()

newConnection()
while true:
  getMessage()
