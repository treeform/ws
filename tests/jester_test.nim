import jester, ws, ws/jester_extra

routes:
  get "/ws":
    try:
      var ws = await newWebSocket(request)
      await ws.send("Welcome to simple echo server")
      while ws.readyState == Open:
        let packet = await ws.receiveStrPacket()
        await ws.send(packet)
    except WebSocketError:
      echo "socket closed"
    result[0] = TCActionRaw # tell jester we handled the request
