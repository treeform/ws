# compile with --threads:on

import ws, asyncdispatch, asynchttpserver
# Threading in nim is kind of hard
# we need an extra lib to make it eaiser:
import shared/seq
# Chreate a chat log to sync chat message between threads
var chatLog = newSharedSeq[string]()
# We can only pass pointers to chat log so create that
var chatLogPtr = unsafeAddr chatLog

proc cb(req: Request) {.async.} =
  if req.url.path == "/ws":
    try:
      var ws = await newWebSocket(req)      
      echo "connected..."
      await ws.send("Welcome to simple chat server")

      # Set this to 0 for full chat history
      # By default no chat history is sent
      var atChatLine = chatLogPtr[].len

      proc writer() {.async.} =
        ## Loops while socket is open, looking for messages to write
        while ws.readyState == Open:
          # if there are chat message we have not sent yet
          # send them
          while atChatLine < chatLogPtr[].len:
            await ws.send(chatLogPtr[][atChatLine])
            inc atChatLine
          # keep the async stuff happy we need to sleep some times
          await sleepAsync(1)

      proc reader() {.async.} =
        # Loops while socket is open, looking for messages to read
        while ws.readyState == Open:
          # this blocks
          var packet = await ws.receiveStrPacket()  
          # add message to chat log
          chatLogPtr[].add(packet)

      # start a async fiber thingy
      asyncCheck writer()
      await reader()
      
    except WebSocketError:
      echo "socket closed:", getCurrentExceptionMsg()
  await req.respond(Http200, "Hello World")

var server = newAsyncHttpServer()
waitFor server.serve(Port(9001), cb)