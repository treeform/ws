import asyncdispatch, asynchttpserver, httpClient, strutils, ws

var server = newAsyncHttpServer()
proc serverCb(req: Request) {.async, gcsafe.} =
  if req.url.path == "/ws":
    try:
      var serverWs = await newWebSocket(req)
    except WebSocketError:
      await req.respond(Http400, "This is a websocket endpoint")
  else:
    await req.respond(Http404, "Not found")

asyncCheck server.serve(Port(9777), serverCb)

var got404 = false
try:
  echo waitFor newAsyncHttpClient().getContent("http://localhost:9777")
  assert false
except:
  got404 = true
  echo "success: got 404 because not /ws"
assert got404

var got400 = false
try:
  echo waitFor newAsyncHttpClient().getContent("http://localhost:9777/ws")
  assert false
except:
  got400 = true
  echo "success: got 400 because made http call to /ws"
assert got400
