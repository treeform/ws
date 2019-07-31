import ws, asyncdispatch, asynchttpserver


var connections = newSeq[WebSocket]()

proc cb(req: Request) {.async, gcsafe.} =
  if req.url.path == "/ws":
    try:
      var ws = await newWebSocket(req)
      connections.add ws
      await ws.send("Welcome to simple chat server")
      while ws.readyState == Open:
        let packet = await ws.receiveStrPacket()
        for other in connections:
          if other.readyState == Open:
            asyncCheck other.send(packet)
    except IOError, WebSocketError:
      echo "socket closed:", getCurrentExceptionMsg()
  await req.respond(Http200, "Hello World")

var server = newAsyncHttpServer()
waitFor server.serve(Port(9001), cb)