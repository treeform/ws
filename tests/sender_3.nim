import ws, asyncdispatch, asynchttpserver, httpclient

# Create three sockets and read from each of them asynchronously

var numOpenWs = 0

proc doStuff(ws: WebSocket, idx: int, msg: string) {.async.} =
  inc numOpenWs
  await ws.send(msg)
  echo idx, ": ", await ws.receiveStrPacket()
  ws.close()
  dec numOpenWs

proc main() {.async.} =
  var
    ws1 = await newWebSocket("wss://echo.websocket.org")
    ws2 = await newWebSocket("wss://echo.websocket.org")
    ws3 = await newWebSocket("wss://echo.websocket.org")

  echo "all sockets opened"

  # depended I/O
  asyncCheck ws1.doStuff(1, "you are first")
  asyncCheck ws2.doStuff(2, "you are second")
  asyncCheck ws3.doStuff(3, "you are third")

  echo "now just waiting for all sockets to close"
  while numOpenWs > 0:
    await sleepAsync(10)

waitFor main()


