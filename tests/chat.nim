import ws, asyncdispatch, asynchttpserver


var connections = newSeq[WebSocket]()

proc cb(req: Request) {.async, gcsafe.} =
  if req.url.path == "/ws":
    try:
      var ws = await newWebsocket(req)
      connections.add ws
      await ws.sendPacket("Welcome to simple chat server")
      while ws.readyState == Open:
        let packet = await ws.receiveStrPacket()
        for other in connections:
          if other.readyState == Open:
            asyncCheck other.sendPacket(packet)
    except IOError:
      echo "socket closed"
  await req.respond(Http200, "Hello World")

var server = newAsyncHttpServer()
waitFor server.serve(Port(9001), cb)