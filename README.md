# Simple WebSocket library for nim.


* Based on the work by niv <n@e-ix.net> https://github.com/niv/websocket.nim
* Also seee rfc https://tools.ietf.org/html/rfc6455

## Examples Echo Server

Example echo server, will repeat what you send it:

```nim
import ws, asyncdispatch, asynchttpserver

var server = newAsyncHttpServer()
proc cb(req: Request) {.async.} =
  if req.url.path == "/ws":
    var ws = await newWebsocket(req)
    await ws.sendPacket("Welcome to simple echo server")
    while ws.readyState == Open:
      let packet = await ws.receiveStrPacket()
      await ws.sendPacket(packet)
  await req.respond(Http200, "Hello World")

waitFor server.serve(Port(9001), cb)
```

```js
ws = new WebSocket("ws://localhost:9001/ws")
ws.send("hi")
```

![alt text](tests/echo.png "Echo server example")


## Examples Chat Server

Example chart server, will send what you send to connected all clients.

```nim
var connections = newSeq[WebSocket]()

proc cb(req: Request) {.async, gcsafe.} =
  if req.url.path == "/ws":
    try:
      var ws = await newWebsocket(req)
      connections.add ws
      await ws.sendPacket("Welcome to simple chat server")
      while ws.readyState == Open:
        let packet = await ws.receiveStrPacket()
        for other in connections:
          if other.readyState == Open:
            asyncCheck other.sendPacket(packet)
    except IOError:
      echo "socket closed"
  await req.respond(Http200, "Hello World")

var server = newAsyncHttpServer()
waitFor server.serve(Port(9001), cb)
```

In one tab:
```js
ws = new WebSocket("ws://localhost:9001/ws")
ws.send("How are you?")
```

Other tab:
```js
ws = new WebSocket("ws://localhost:9001/ws")
ws.send("Good, you?")
```

