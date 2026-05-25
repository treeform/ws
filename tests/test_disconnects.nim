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
    let ws = await newWebSocket(req)
    {.gcsafe.}:
      curWs = ws
    await ws.send("Welcome to simple echo server")
    while ws.readyState == Open:
      echo "reading..."
      let packet = await ws.receivePacket()
      echo "sending..."
      await ws.send($packet)
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
