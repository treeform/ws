import asyncdispatch, asynchttpserver, ws

proc cb(req: Request) {.async.} =
  try:
    var ws = await newWebSocket(req)
    await ws.send("Welcome to disconnection server")
    for i in 0 ..< 5:
      await ws.send("disconnecting in " & $(5 - i))
      await sleepAsync(1000)
    ws.close()

  except WebSocketClosedError:
    echo "socket closed:", getCurrentExceptionMsg()

var server = newAsyncHttpServer()
waitFor server.serve(Port(9001), cb)
