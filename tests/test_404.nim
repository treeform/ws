import asyncdispatch, asynchttpserver, ws

block:
  # Start server
  var
    hadFailedNewSocket = false
    sent404 = false
  proc cb(req: Request) {.async.} =
    sent404 = true
    await req.respond(Http404, "Invalid")
  var server = newAsyncHttpServer()
  asyncCheck server.serve(Port(9002), cb)

  # Send request
  var ws: WebSocket
  try:
    ws = waitFor newWebSocket("ws://127.0.0.1:9002")
  except WebSocketError:
    hadFailedNewSocket = true
  server.close()
  assert hadFailedNewSocket
  assert sent404
  assert ws == nil
