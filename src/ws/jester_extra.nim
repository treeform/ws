import jester, ws, asyncdispatch, asynchttpserver, strutils, std/sha1, base64, nativesockets

proc newWebSocket*(req: jester.Request): Future[WebSocket] {.async.} =
  ## Creates a new socket from a jester request.
  when defined(useHttpBeast):
    raise newException("Websockets dont supprot http beast.")
  else:
    let req: asynchttpserver.Request = cast[asynchttpserver.Request](req.getNativeReq())
    return await ws.newWebSocket(req)  