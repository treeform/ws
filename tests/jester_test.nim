import jester
import ws, ws/jester_extra

routes:
  get "/ws": 
    var ws = await newWebSocket(request)
    await ws.send("Welcome to simple echo server")
    while ws.readyState == Open:
      let packet = await ws.receiveStrPacket()
      await ws.send(packet)