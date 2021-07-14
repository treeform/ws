include ../src/ws

block:
  # Start server
  proc cb(req: Request) {.async.} =
    if req.headers.hasKey("Sec-WebSocket-Protocol"):
      if "foo1" in req.headers["Sec-WebSocket-Protocol"].toSeq():
        var ws = await newWebSocket(req, protocol = "foo1")
        await ws.send("Welcome foo1")
        ws.close()
      elif "foo2" in req.headers["Sec-WebSocket-Protocol"].toSeq():
        var ws = await newWebSocket(req, protocol = "foo2")
        await ws.send("Welcome foo2")
        ws.close()
      else:
        await req.respond(Http404, "Invalid")
  var server = newAsyncHttpServer()
  asyncCheck server.serve(Port(9002), cb)

  block:
    var ws = waitFor newWebSocket("ws://127.0.0.1:9002/ws", protocols = @["foo1", "foo2"])
    assert ws.protocol == "foo1"
    assert waitFor(ws.receiveStrPacket()) == "Welcome foo1"
    ws.close()

  block:
    var ws = waitFor newWebSocket("ws://127.0.0.1:9002/ws", protocols = @["foo2"])
    assert ws.protocol == "foo2"
    assert waitFor(ws.receiveStrPacket()) == "Welcome foo2"
    ws.close()

  block:
    var ws = waitFor newWebSocket("ws://127.0.0.1:9002/ws", protocols = @["foo1"])
    assert ws.protocol == "foo1"
    assert waitFor(ws.receiveStrPacket()) == "Welcome foo1"
    ws.close()

  block:
    try:
      var ws = waitFor newWebSocket("ws://127.0.0.1:9002/ws", protocols = @["notfoo"])
      assert false
    except WebSocketError:
      assert true

  server.close()
