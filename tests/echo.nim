import asyncdispatch, asynchttpserver, ws

proc cb(req: Request) {.async.} =
  if req.url.path == "/ws":
    try:
      var ws = await newWebSocket(req)
      await ws.send("Welcome to echo server")
      if ws.protocol != "":
        await ws.send("Using protocol: " & ws.protocol)
      while ws.readyState == Open:
        let packet = await ws.receiveStrPacket()
        await ws.send(packet)
    except WebSocketError:
      echo "socket closed:", getCurrentExceptionMsg()
  await req.respond(Http200, "Hello World")

var server = newAsyncHttpServer()
waitFor server.serve(Port(9001), cb)
