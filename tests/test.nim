include ../src/ws

assert 0b10000000u8[0] == true
assert 0b00000000u8[0] == false

assert 0b00001000u8[4] == true
assert 0b00010000u8[4] == false

assert 0b00000001u8[7] == true
assert 0b01111110u8[7] == false


assert nibbleFromChar('F') == 15
assert nibbleFromChar('a') == 10
assert nibbleFromChar('5') == 5
assert nibbleFromChar('0') == 0

assert nibbleToChar(15) == 'f'
assert nibbleToChar(10) == 'a'
assert nibbleToChar(5) == '5'
assert nibbleToChar(0) == '0'

assert encodeHex("hi how are you?") == "686920686f772061726520796f753f"
assert decodeHex("686920686f772061726520796f753f") == "hi how are you?"

block: # 7bit length
  assert encodeFrame((
    fin: true,
    rsv1: false,
    rsv2: false,
    rsv3: false,
    opcode: Opcode.Text,
    mask: false,
    data: "hi there"
  )) == "\129\8hi there"

block: # 7+16 bits length
  var data = ""
  for i in 0..32:
    data.add "How are you this is the payload!!!"
  assert encodeFrame((
    fin: true,
    rsv1: false,
    rsv2: false,
    rsv3: false,
    opcode: Opcode.Text,
    mask: false,
    data: data
  ))[0..32] == "\129~\4bHow are you this is the paylo"

block: # 7+64 bits length
  var data = ""
  for i in 0..3200:
    data.add "How are you this is the payload!!!"
  assert encodeFrame((
    fin: true,
    rsv1: false,
    rsv2: false,
    rsv3: false,
    opcode: Opcode.Text,
    mask: false,
    data: data
  ))[0..32] == "\129\127\0\0\0\0\0\1\169\"How are you this is the"

block: # masking
  assert encodeFrame((
    fin: true,
    rsv1: false,
    rsv2: false,
    rsv3: false,
    opcode: Opcode.Text,
    mask: true,
    data: "hi there"
  )) == "\129\136\13M\137/e$\169[e(\251J"