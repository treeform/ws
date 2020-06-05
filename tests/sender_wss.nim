import asyncdispatch, asynchttpserver, httpclient, ws

proc main() {.async.} =
  var ws = await newWebSocket("wss://echo.websocket.org")
  await ws.send("Hi, how are you?")
  echo await ws.receiveStrPacket()
  ws.close()

waitFor main()
