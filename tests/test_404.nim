import ws, asyncdispatch, asynchttpserver

block:
  # Start server
  var
    hadFailedNewSocket = false
  proc cb(req: Request) {.async.} =
    await req.respond(Http404, "Invalid")
  var server = newAsyncHttpServer()
  asyncCheck server.serve(Port(9002), cb)

  # Send request
  var ws: WebSocket
  try:
    ws = waitFor newWebSocket("ws://127.0.0.1:9002")
  except:
    hadFailedNewSocket = true
  server.close()
  assert hadFailedNewSocket
  assert ws == nil
