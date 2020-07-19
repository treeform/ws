include ../src/ws

block: # protocol mismatch
  # Start server
  var
    hadProtocolMismatch = false
    hadFailedNewSocket = false
  proc cb(req: Request) {.async.} =
    try:
      var ws = await newWebSocket(req, protocol = "foo")
      await ws.send("Welcome")
      ws.close()
    except:
      if getCurrentExceptionMsg().startsWith("Protocol mismatch (expected: foo, got: foo2)"):
        hadProtocolMismatch = true
      req.client.close()
  var server = newAsyncHttpServer()
  asyncCheck server.serve(Port(9002), cb)
  # Send request
  try:
    var ws = waitFor newWebSocket("ws://127.0.0.1:9002/ws", protocol = "foo2")
    ws.close()
  except:
    hadFailedNewSocket = true
  server.close()
  assert hadProtocolMismatch
  assert hadFailedNewSocket
