import ws, asyncdispatch, asynchttpserver, strutils, std/sha1, base64, nativesockets
import jester, jester/private/utils

when useHttpBeast:
  import httpbeast, options, asyncnet


  proc newWebSocket*(req: httpbeast.Request): Future[WebSocket] {.async.} =
    ## Creates a new socket from an httpbeast request.
    try:
      let headers = req.headers.get

      if not headers.hasKey("Sec-WebSocket-Version"):
        req.send(Http404, "Not Found")
        raise newException(WebSocketError, "Not a valid websocket handshake.")
  
      var ws = WebSocket()
      ws.masked = false

      # Here is the magic:
      req.forget() # Remove from HttpBeast event loop.
      asyncdispatch.register(req.client.AsyncFD) # Add to async event loop.
      
      ws.tcpSocket = newAsyncSocket(req.client.AsyncFD)
      await ws.handshake(headers)
      return ws

    except ValueError, KeyError:
      # Wrap all exceptions in a WebSocketError so its easy to catch
      raise newException(
        WebSocketError, 
        "Failed to create WebSocket from request: " & getCurrentExceptionMsg()
      )


proc newWebSocket*(req: jester.Request): Future[WebSocket] {.async.} =  
  ## Creates a new socket from a jester request.
  return await newWebSocket(req.getNativeReq())  