import asyncdispatch, asynchttpserver, ws

proc cb(req: Request) {.async.} =
  var ws = await newWebSocket(req)
  await ws.send("Welcome")
  ws.close()

var server = newAsyncHttpServer()
waitFor server.serve(Port(9001), cb)
