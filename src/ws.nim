import httpcore, httpclient, asynchttpserver, asyncdispatch, nativesockets,
  asyncnet, strutils, streams, random, std/sha1, base64, uri, strformat, httpcore

type
  ReadyState* = enum
    Connecting = 0            # The connection is not yet open.
    Open = 1                  # The connection is open and ready to communicate.
    Closing = 2               # The connection is in the process of closing.
    Closed = 3                # The connection is closed or couldn't be opened.

  WebSocket* = ref object
    req*: Request
    version*: int
    key*: string
    protocol*: string
    readyState*: ReadyState

  WebSocketError* = object of Exception

template `[]`(value: uint8, index: int): bool =
  ## get bits from uint8, uint8[2] gets 2nd bit
  (value and (1 shl (7 - index))) != 0


proc nibbleFromChar(c: char): int =
  ## converts hex chars like `0` to 0 and `F` to 15
  case c:
    of '0'..'9': (ord(c) - ord('0'))
    of 'a'..'f': (ord(c) - ord('a') + 10)
    of 'A'..'F': (ord(c) - ord('A') + 10)
    else: 255


proc nibbleToChar(value: int): char =
  ## converts number like 0 to `0` and 15 to `fg`
  case value:
    of 0..9: char(value + ord('0'))
    else: char(value + ord('a') - 10)


proc decodeBase16*(str: string): string =
  ## base16 decode a string
  result = newString(str.len div 2)
  for i in 0 ..< result.len:
    result[i] = chr(
      (nibbleFromChar(str[2 * i]) shl 4) or
      nibbleFromChar(str[2 * i + 1]))


proc encodeBase16*(str: string): string =
  ## base61 encode a string
  result = newString(str.len * 2)
  for i, c in str:
    result[i * 2] = nibbleToChar(ord(c) shr 4)
    result[i * 2 + 1] = nibbleToChar(ord(c) and 0x0f)


proc genMaskKey*(): array[4, char] =
  ## Generates a random key of 4 random chars
  proc r(): char = char(rand(256))
  [r(), r(), r(), r()]


proc newWebSocket*(req: Request): Future[WebSocket] {.async.} =
  ## Creates a new socket from a request
  if not req.headers.hasKey("sec-websocket-version"):
    await req.respond(Http404, "Not Found")
    raise newException(WebSocketError, "Not a valid websocket handshake.")

  var ws = WebSocket()
  ws.req = req
  ws.version = parseInt(req.headers["sec-webSocket-version"])
  ws.key = req.headers["sec-webSocket-key"].strip()
  if req.headers.hasKey("sec-webSocket-protocol"):
    ws.protocol = req.headers["sec-websocket-protocol"].strip()

  let sh = secureHash(ws.key & "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
  let acceptKey = base64.encode(decodeBase16($sh))

  var responce = "HTTP/1.1 101 Web Socket Protocol Handshake\c\L"
  responce.add("Sec-WebSocket-Accept: " & acceptKey & "\c\L")
  responce.add("Connection: Upgrade\c\L")
  responce.add("Upgrade: webSocket\c\L")
  if not ws.protocol.len == 0:
    responce.add("Sec-WebSocket-Protocol: " & ws.protocol & "\c\L")
  responce.add "\c\L"

  await ws.req.client.send(responce)
  ws.readyState = Open
  return ws


proc newWebSocket*(url: string): Future[WebSocket] {.async.} =
  ## Creates a client
  var ws = WebSocket()
  ws.req = Request()
  ws.req.client = newAsyncSocket()

  var uri = parseUri(url)
  var port = Port(9001)
  case uri.scheme
    of "wss":
      uri.scheme = "https"
      port = Port(443)
    of "ws":
      uri.scheme = "http"
      port = Port(80)
    else:
      raise newException(WebSocketError,
          &"Scheme {uri.scheme} not supported yet.")
  if uri.port.len > 0:
    port = Port(parseInt(uri.port))

  var client = newAsyncHttpClient()
  client.headers = newHttpHeaders({
    "Connection": "Upgrade",
    "Upgrade": "websocket",
    "Sec-WebSocket-Version": "13",
    "Sec-WebSocket-Key": "JCSoP2Cyk0cHZkKAit5DjA==",
    "Sec-WebSocket-Extensions": "permessage-deflate; client_max_window_bits"
  })
  var _ = await client.get(url)
  ws.req.client = client.getSocket()

  ws.readyState = Open
  return ws


type
  Opcode* = enum
    ## 4 bits. Defines the interpretation of the "Payload data".
    Cont = 0x0                ## denotes a continuation frame
    Text = 0x1                ## denotes a text frame
    Binary = 0x2              ## denotes a binary frame
    # 3-7 are reserved for further non-control frames
    Close = 0x8               ## denotes a connection close
    Ping = 0x9                ## denotes a ping
    Pong = 0xa                ## denotes a pong
    # B-F are reserved for further control frames

  #[
   0                   1                   2                   3
   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
  +-+-+-+-+-------+-+-------------+-------------------------------+
  |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
  |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
  |N|V|V|V|       |S|             |   (if payload len==126/127)   |
  | |1|2|3|       |K|             |                               |
  +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
  |     Extended payload length continued, if payload len == 127  |
  + - - - - - - - - - - - - - - - +-------------------------------+
  |                               |Masking-key, if MASK set to 1  |
  +-------------------------------+-------------------------------+
  | Masking-key (continued)       |          Payload Data         |
  +-------------------------------- - - - - - - - - - - - - - - - +
  :                     Payload Data continued ...                :
  + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
  |                     Payload Data continued ...                |
  +---------------------------------------------------------------+
  ]#
  Frame* = tuple
    fin: bool ## Indicates that this is the final fragment in a message.
    rsv1: bool ## MUST be 0 unless negotiated that defines meanings
    rsv2: bool
    rsv3: bool
    opcode: Opcode ## Defines the interpretation of the "Payload data".
    mask: bool                ## Defines whether the "Payload data" is masked.
    data: string              ## Payload data


proc encodeFrame*(f: Frame): string =
  ## Encodes a frame into a string buffer
  ## See https://tools.ietf.org/html/rfc6455#section-5.2

  var ret = newStringStream()

  var b0 = (f.opcode.uint8 and 0x0f) # 0th byte: opcodes and flags
  if f.fin:
    b0 = b0 or 128u8

  ret.write(b0)

  # Payload length can be 7 bits, 7+16 bits, or 7+64 bits
  # 1st byte: playload len start and mask bit
  var b1 = 0u8

  if f.data.len <= 125:
    b1 = f.data.len.uint8
  elif f.data.len > 125 and f.data.len <= 0xffff:
    b1 = 126u8
  else:
    b1 = 127u8

  if f.mask:
    b1 = b1 or (1 shl 7)

  ret.write(uint8 b1)

  # Only need more bytes if data len is 7+16 bits, or 7+64 bits
  if f.data.len > 125 and f.data.len <= 0xffff:
    # data len is 7+16 bits
    ret.write(htons(f.data.len.uint16))
  elif f.data.len > 0xffff:
    # data len is 7+64 bits
    var len = f.data.len
    ret.write char((len shr 56) and 255)
    ret.write char((len shr 48) and 255)
    ret.write char((len shr 40) and 255)
    ret.write char((len shr 32) and 255)
    ret.write char((len shr 24) and 255)
    ret.write char((len shr 16) and 255)
    ret.write char((len shr 8) and 255)
    ret.write char(len and 255)

  var data = f.data

  if f.mask:
    # if we need to maks it generate random mask key and mask the data
    let maskKey = genMaskKey()
    for i in 0..<data.len:
      data[i] = (data[i].uint8 xor maskKey[i mod 4].uint8).char
    # write mask key next
    ret.write(maskKey)

  # write the data
  ret.write(data)
  ret.setPosition(0)
  return ret.readAll()


proc send*(ws: WebSocket, text: string): Future[void] {.async.} =
  ## write data to WebSocket
  var frame = encodeFrame((
    fin: true,
    rsv1: false,
    rsv2: false,
    rsv3: false,
    opcode: Opcode.Text,
    mask: false,
    data: text
  ))
  const maxSize = 1024*1024
  # send stuff in 1 megabyte chunks to prevent IOErrors
  # with really large packets
  var i = 0
  while i < frame.len:
    let data = frame[i ..< min(frame.len, i + maxSize)]
    await ws.req.client.send(data)
    i += maxSize
    await sleepAsync(1)


proc recvFrame(ws: WebSocket): Future[Frame] {.async.} =
  ## Gets a frame from the WebSocket
  ## See https://tools.ietf.org/html/rfc6455#section-5.2

  if cast[int](ws.req.client.getFd) == -1:
    ws.readyState = Closed
    return result

  # grab the header
  let header = await ws.req.client.recv(2)

  if header.len != 2:
    ws.readyState = Closed
    raise newException(WebSocketError, "socket closed")

  let b0 = header[0].uint8
  let b1 = header[1].uint8

  # read the flags and fin from the header
  result.fin = b0[0]
  result.rsv1 = b0[1]
  result.rsv2 = b0[2]
  result.rsv3 = b0[3]
  result.opcode = (b0 and 0x0f).Opcode

  # if any of the rsv are set close the socket
  if result.rsv1 or result.rsv2 or result.rsv3:
    ws.readyState = Closed
    raise newException(WebSocketError, "WebSocket Potocol missmatch")

  # Payload length can be 7 bits, 7+16 bits, or 7+64 bits
  var finalLen: uint = 0

  let headerLen = uint(b1 and 0x7f)
  if headerLen == 0x7e:
    # length must be 7+16 bits
    var lenstr = await ws.req.client.recv(2)
    if lenstr.len != 2:
      raise newException(WebSocketError, "Socket closed")

    finalLen = cast[ptr uint16](lenstr[0].addr)[].htons

  elif headerLen == 0x7f:
    # length must be 7+64 bits
    var lenstr = await ws.req.client.recv(8)
    if lenstr.len != 8:
      raise newException(WebSocketError, "Socket closed")
    finalLen = cast[ptr uint32](lenstr[4].addr)[].htonl

  else:
    # length must be 7 bits
    finalLen = headerLen

  # do we need to apply mask?
  result.mask = (b1 and 0x80) == 0x80
  var maskKey = ""
  if result.mask:
    # read mask
    maskKey = await ws.req.client.recv(4)
    if maskKey.len != 4:
      raise newException(WebSocketError, "Socket closed")

  # read the data
  result.data = await ws.req.client.recv(int finalLen)
  if result.data.len != int finalLen:
    raise newException(WebSocketError, "Socket closed")

  if result.mask:
    # apply mask if we need too
    for i in 0 ..< result.data.len:
      result.data[i] = (result.data[i].uint8 xor maskKey[i mod 4].uint8).char


proc receiveStrPacket*(ws: WebSocket): Future[string] {.async.} =
  ## wait for a string packet to come
  var frame = await ws.recvFrame()
  if frame.opcode == Text or frame.opcode == Binary:
    result = frame.data
    # If there are more parts read and wait for them
    while frame.fin != true:
      frame = await ws.recvFrame()
      if frame.opcode != Cont:
        raise newException(WebSocketError,
            "Socket did not get continue frame")
      result.add frame.data
    return
  else:
    raise newException(WebSocketError,
      "Socket got invalid frame, looking for Text or Binary")


proc close*(ws: WebSocket) =
  ## close the socket
  ws.readyState = Closed
  ws.req.client.close()
