include ../src/ws

# Start server
proc cb(req: Request) {.async.} =
  var ws = await newWebSocket(req)
  if req.headers.hasKey("Authorization") and req.headers["Authorization"] == "Basic Zm9vOmJhcg==": 
    await ws.send("Welcome")
  else:
    await ws.send("Bad Credential")  
  ws.close()

var server = newAsyncHttpServer()
asyncCheck server.serve(Port(9001), cb)

# Send request
let extraHeaders = @[("Authorization", "Basic Zm9vOmJhcg==")] # Base64 foo:bar
let url = "ws://127.0.0.1:9001/ws"
var ws = waitFor newWebSocket(url = url, extraHeaders = extraHeaders)
let packet = waitFor ws.receiveStrPacket()

assert packet == "Welcome"

ws.close()
server.close()
