import ws, asyncdispatch, asynchttpserver

proc main() {.async.} =
  # connect with "alpha" websocket protocol
  var ws = await newWebSocket("ws://127.0.0.1:9001/ws", protocol = "alpha")
  echo await ws.receiveStrPacket()
  await ws.send("Hi, how are you?")
  echo await ws.receiveStrPacket()
  ws.close()

waitFor main()


