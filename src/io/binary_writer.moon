-- BinaryWriter: Efficient binary data writing with type conversion
-- Companion to BinaryReader for DBC file creation and modification

class BinaryWriter
  new: =>
    @buffer = {}
    @position = 0

  seek: (position) =>
    @position = position
    @

  tell: => @position

  write_uint8: (value) =>
    assert value >= 0 and value <= 255, "Invalid uint8 value: #{value}"
    @buffer[@position + 1] = string.char(value)
    @position += 1
    @

  write_uint16_le: (value) =>
    assert value >= 0 and value <= 65535, "Invalid uint16 value: #{value}"
    @buffer[@position + 1] = string.char(value % 256)
    @buffer[@position + 2] = string.char(math.floor(value / 256) % 256)
    @position += 2
    @

  write_uint32_le: (value) =>
    assert value >= 0 and value <= 4294967295, "Invalid uint32 value: #{value}"
    @buffer[@position + 1] = string.char(value % 256)
    @buffer[@position + 2] = string.char(math.floor(value / 256) % 256)
    @buffer[@position + 3] = string.char(math.floor(value / 65536) % 256)
    @buffer[@position + 4] = string.char(math.floor(value / 16777216) % 256)
    @position += 4
    @

  write_int32_le: (value) =>
    assert value >= -2147483648 and value <= 2147483647, "Invalid int32 value: #{value}"
    unsigned_value = value < 0 and (value + 4294967296) or value
    @write_uint32_le unsigned_value

  write_float32_le: (value) =>
    -- Convert float to IEEE 754 format
    if value == 0
      @write_uint32_le 0
      return @

    sign = value < 0 and 1 or 0
    value = math.abs value

    if value == math.huge
      @write_uint32_le sign == 1 and 0xFF800000 or 0x7F800000
      return @

    if value ~= value -- NaN check
      @write_uint32_le 0x7FC00000
      return @

    -- Calculate exponent and mantissa
    exponent = math.floor(math.log(value) / math.log(2))
    mantissa = value / (2^exponent) - 1

    -- Adjust for IEEE 754 bias
    exponent += 127

    if exponent <= 0
      mantissa = value / (2^(-126))
      exponent = 0
    elseif exponent >= 255
      mantissa = 0
      exponent = 255

    -- Pack into 32 bits
    mantissa_bits = math.floor(mantissa * (2^23))
    ieee_bits = (sign * (2^31)) + (exponent * (2^23)) + mantissa_bits
    @write_uint32_le ieee_bits

  write_string: (str, length = nil) =>
    if length
      str = str\sub(1, length)
      str = str .. string.rep('\0', length - #str)
      for i = 1, length
        @buffer[@position + i] = str\sub(i, i)
      @position += length
    else
      for i = 1, #str
        @buffer[@position + i] = str\sub(i, i)
      @position += #str
    @

  write_cstring: (str) =>
    @write_string str
    @write_uint8 0
    @

  get_data: =>
    table.concat @buffer

  get_size: =>
    @position

BinaryWriter