import asyncdispatch, asynchttpserver, ws

proc main() {.async.} =
  var ws = await newWebSocket("ws://127.0.0.1:9001/ws")
  echo await ws.receiveStrPacket()
  await ws.send("Hi, how are you?")
  echo await ws.receiveStrPacket()
  ws.close()

waitFor main()
