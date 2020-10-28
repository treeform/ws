include ../src/ws

# Start server
proc cb(req: Request) {.async.} =
  var ws = await newWebSocket(req)
  await ws.send("Welcome")
  ws.close()
var server = newAsyncHttpServer()
asyncCheck server.serve(Port(9001), cb)
# Send request
var ws = waitFor newWebSocket("ws://127.0.0.1:9001/ws")
let packet = waitFor ws.receiveStrPacket()

assert packet == "Welcome"

ws.close()
server.close()
