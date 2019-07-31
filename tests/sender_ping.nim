import ws, asyncdispatch, asynchttpserver

proc main() {.async.} =
  # connect with "alpha" websocket protocol
  var ws = await newWebSocket("ws://127.0.0.1:9001/ws", protocol = "alpha")
  echo await ws.receiveStrPacket()
  await ws.send("Hi, how are you?")
  echo await ws.receiveStrPacket()

  ## You can send pings manually
  for i in 0 .. 5:
    echo "ping"
    await ws.ping()
    await sleepAsync(1)

  ## Or set them to be sent N seconds appart while the socket is open:
  ws.setupPings(5) # every 5 seconds

  echo "Ctr-C to exit"
  while true:
    await sleepAsync(1)

  ws.close()

waitFor main()


