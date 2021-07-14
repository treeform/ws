import asyncdispatch, asynchttpserver, strutils, ws

var server = newAsyncHttpServer()
var curWs: WebSocket

proc gameLoop(){.async.} =
  for i in 0 .. 5:
    echo "gameLoop:" & $i
    if i == 4:
      curWs.close()
    await sleepAsync(1000)
  quit()

proc serverCb(req: Request) {.async, gcsafe.} =
  try:
    curWs = await newWebSocket(req)
    await curWs.send("Welcome to simple echo server")
    while curWs.readyState == Open:
      echo "reading..."
      let packet = await curWs.receivePacket()
      echo "sending..."
      await curWs.send($packet)
  except WebSocketError:
    echo "serverCb exception:", getCurrentExceptionMsg().split("\n")[0]

proc clientLoop(){.async, gcsafe.} =
  await sleepAsync(1000)
  try:
    var clientWs = await newWebSocket("ws://localhost:9777")
    while clientWs.readyState == Open:
      var packet = await clientWs.receivePacket()
      echo $packet
  except WebSocketError:
    echo "clientLoop exception:", getCurrentExceptionMsg().split("\n")[0]

asyncCheck gameLoop()
asyncCheck clientLoop()
waitFor server.serve(Port(9777), serverCb)
