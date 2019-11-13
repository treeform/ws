import ws, asyncdispatch, asynchttpserver

proc cb(req: Request) {.async.} =
  var ws = await newWebSocket(req)
  echo "Got ws connecting with protocol ", ws.protocol
  if ws.protocol == "alpha":
    await ws.send("Welcome Protocol Alpha")
  ws.close()

var server = newAsyncHttpServer()
waitFor server.serve(Port(9001), cb)