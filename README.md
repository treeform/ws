<img src="docs/wsBanner.png">

# Simple WebSocket library for nim.

* Based on the work by niv https://github.com/niv/websocket.nim
* Also see rfc https://tools.ietf.org/html/rfc6455

This library is being actively developed and we'd be happy for you to use it.

`nimble install ws`

![Github Actions](https://github.com/treeform/ws/workflows/Github%20Actions/badge.svg)

Features:
* Client and Server Side WebSocket
* Async/Await Support
* WebSocket Protocols
* Timeouts and Disconnects

### Documentation

API reference: https://nimdocs.com/treeform/ws/

## Example Echo Server:

Example echo server, will repeat what you send it:

```nim
import ws, asyncdispatch, asynchttpserver

var server = newAsyncHttpServer()
proc cb(req: Request) {.async.} =
  if req.url.path == "/ws":
    var ws = await newWebSocket(req)
    await ws.send("Welcome to simple echo server")
    while ws.readyState == Open:
      let packet = await ws.receiveStrPacket()
      await ws.send(packet)
  else:
    await req.respond(Http404, "Not found")

waitFor server.serve(Port(9001), cb)
```

And then in the browser type this JavaScript:

```js
ws = new WebSocket("ws://localhost:9001/ws")
ws.send("hi")
```

![alt text](tests/echo.png "Echo server example")


## Example Chat Server:

Example chat server, will send what you send to connected all clients.

```nim
import ws, asyncdispatch, asynchttpserver

var connections = newSeq[WebSocket]()

proc cb(req: Request) {.async, gcsafe.} =
  if req.url.path == "/ws":
    try:
      var ws = await newWebSocket(req)
      connections.add ws
      await ws.send("Welcome to simple chat server")
      while ws.readyState == Open:
        let packet = await ws.receiveStrPacket()
        for other in connections:
          if other.readyState == Open:
            asyncCheck other.send(packet)
    except WebSocketError:
      echo "socket closed:", getCurrentExceptionMsg()
  else:
    await req.respond(Http404, "Not found")

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

## Example client socket:

Instead of being the server you are the client connecting to some other server:

```nim
var ws = await newWebSocket("ws://127.0.0.1:9001/ws")
echo await ws.receiveStrPacket()
await ws.send("Hi, how are you?")
echo await ws.receiveStrPacket()
ws.close()
```

SSL is also supported:
```nim
var ws = await newWebSocket("wss://echo.websocket.org")
```

You can also pass a protocol
```nim
var ws = await newWebsocket("wss://echo.websocket.org", protocol = "alpha")
```

## Using with Jester

If you use using `ws` with `jester` library you need to import jester_extra:

```nim
import jester
import ws, ws/jester_extra

routes:
  get "/ws":
    var ws = await newWebSocket(request)
    await ws.send("Welcome to simple echo server")
    while ws.readyState == Open:
      let packet = await ws.receiveStrPacket()
      await ws.send(packet)
```
