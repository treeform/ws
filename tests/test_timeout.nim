import asyncdispatch, asynchttpserver, ws

block:
  # Start server
  proc cb(req: Request) {.async.} =
    # Do nothing.
    discard
  var server = newAsyncHttpServer()
  asyncCheck server.serve(Port(9002), cb)

  proc timeout() {.async.} =
    # Should time out here:
    await sleepAsync(1)
    assert true
    quit()

  asyncCheck timeout()

  # Send request.
  var ws: WebSocket
  ws = waitFor newWebSocket("ws://127.0.0.1:9002")
  assert false # Should never get here.
