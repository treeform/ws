import ws, asyncdispatch, asynchttpserver

proc main() {.async.} =
  # connect with "alpha" websocket protocol
  var ws = await newWebSocket("ws://127.0.0.1:9001/ws", protocol = "alpha")
  ws.close()

waitFor main()


