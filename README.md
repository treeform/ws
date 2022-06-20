<img src="docs/wsBanner.png">

# Simple WebSocket library for nim.

`nimble install ws`

![Github Actions](https://github.com/treeform/ws/workflows/Github%20Actions/badge.svg)

[API reference](https://nimdocs.com/treeform/ws)

This library has no dependencies other than the Nim standard library.

## About

I love webSockets. They are easy to use and supported everywhere. I use them instead of HTTP REST APIs. I find it much easier to think in terms of client/server messages then verbs and resource paths. Inevitably you want the server to notify the client when some thing changes. Inevitably you will use webSockets. Then you will have two systems. Stop the pain and just use plain webSockets from the start. Say no to REST.

I recommend having only a webSocket server and host static html/js/css files some place like Amazon S3 or Google CloudStore. For HTTPS (or WSS in webSocket case) I usually wrap my webSocket server with Nginx with Let's Encrypt CertBot, and I also have just simply wrapped it with CloudFlare.

This was originally based on the work by niv https://github.com/niv/websocket.nim. Thank you!

This library is being actively developed and we'd be happy for you to use it.

`nimble install ws`

![Github Actions](https://github.com/treeform/ws/workflows/Github%20Actions/badge.svg)

Features:
* Client and Server Side WebSocket
* Async/Await Support
* WebSocket Protocols
* Timeouts and Disconnects
* SSL support
* Jester support
* Compliant with the [WebSocket protocol](https://tools.ietf.org/html/rfc6455).

### Documentation

API reference: https://nimdocs.com/treeform/ws/

## Example Echo Server:

Example echo server, will repeat what you send it:

```nim
import asyncdispatch, asynchttpserver, ws

var connections = newSeq[WebSocket]()

proc cb(req: Request) {.async, gcsafe.} =
  if req.url.path == "/ws":
    try:
      var ws = await newWebSocket(req)
      connections.add ws
      await ws.send("Welcome to simple chat server")
      while ws.readyState == Open:
        let packet = await ws.receiveStrPacket()
        echo "Received packet: " & packet
        for other in connections:
          if other.readyState == Open:
            asyncCheck other.send(packet)
    except WebSocketClosedError:
      echo "Socket closed. "
    except WebSocketProtocolMismatchError:
      echo "Socket tried to use an unknown protocol: ", getCurrentExceptionMsg()
    except WebSocketError:
      echo "Unexpected socket error: ", getCurrentExceptionMsg()
  await req.respond(Http200, "Hello World")

var server = newAsyncHttpServer()
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

In one browser tab:
```js
// JavaScript code:
ws = new WebSocket("ws://localhost:9001/ws")
ws.send("How are you?")
```

Other browser tab:
```js
// JavaScript code:
ws = new WebSocket("ws://localhost:9001/ws")
ws.send("Good, you?")
```

## Example client socket:

Instead of being the server you are the client connecting to some other server:

```nim
import asyncdispatch, asynchttpserver, ws

proc main() {.async.} =
  var ws = await newWebSocket("ws://127.0.0.1:9001/ws")
  echo await ws.receiveStrPacket()
  await ws.send("Hi, how are you?")
  echo await ws.receiveStrPacket()
  ws.close()

waitFor main()
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
