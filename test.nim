import ws, asyncdispatch

proc sendRemote(ws: WebSocket, data: string): Future[string] {.async.} =
  await ws.send(data)
  result = await ws.receiveStrPacket()
