import ws, asyncdispatch, asynchttpserver

proc cb(req: Request) {.async.} =
  if req.url.path == "/ws":
    try:
      var ws = await newWebsocket(req)
      await ws.sendPacket("Welcome to echo server")
      while ws.readyState == Open:
        let packet = await ws.receiveStrPacket()
        await ws.sendPacket(packet)
    except IOError:
      echo "socket closed"
  await req.respond(Http200, "Hello World")

var server = newAsyncHttpServer()
waitFor server.serve(Port(9001), cb)