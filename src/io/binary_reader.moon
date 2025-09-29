-- BinaryReader: Efficient binary data reading with type conversion
-- Inspired by bin.lua but with OOP design and optimizations

import floor from math

class BinaryReader
  new: (data) =>
    assert type(data) == "string", "BinaryReader expects string data"
    @data = data
    @length = #data
    @position = 0
    @_cache = {} -- Cache for frequently accessed values

  -- Core reading methods with bounds checking
  _check_bounds: (size) =>
    if @position + size > @length
      error "BinaryReader: attempt to read beyond data boundaries (pos: #{@position}, size: #{size}, length: #{@length})"

  seek: (position) =>
    assert position >= 0 and position <= @length, "Invalid seek position"
    @position = position
    @

  skip: (bytes) =>
    @position += bytes
    @

  tell: => @position

  remaining: => @length - @position

  -- Optimized byte reading using string.byte
  read_bytes: (count, offset = @position) =>
    @_check_bounds count
    bytes = [@data\byte i for i = offset + 1, offset + count]
    @position = offset + count unless offset != @position
    bytes

  -- Little-endian unsigned integer readers
  read_uint8: (offset = @position) =>
    @_check_bounds 1
    value = @data\byte offset + 1
    @position = offset + 1 unless offset != @position
    value

  read_uint16_le: (offset = @position) =>
    @_check_bounds 2
    a, b = @data\byte offset + 1, offset + 2
    a, b = a or 0, b or 0  -- Handle nil values
    value = b * 256 + a
    @position = offset + 2 unless offset != @position
    value

  read_uint32_le: (offset = @position) =>
    @_check_bounds 4
    a, b, c, d = @data\byte offset + 1, offset + 2, offset + 3, offset + 4
    a, b, c, d = a or 0, b or 0, c or 0, d or 0  -- Handle nil values
    value = d * 256^3 + c * 256^2 + b * 256 + a
    @position = offset + 4 unless offset != @position
    value

  -- Little-endian signed integer readers
  read_int8: (offset = @position) =>
    value = @read_uint8 offset
    value > 127 and (value - 256) or value

  read_int16_le: (offset = @position) =>
    value = @read_uint16_le offset
    value > 32767 and (value - 65536) or value

  read_int32_le: (offset = @position) =>
    value = @read_uint32_le offset
    value > 2147483647 and (value - 4294967296) or value

  -- IEEE 754 single precision float reader
  read_float32_le: (offset = @position) =>
    @_check_bounds 4
    a, b, c, d = @data\byte offset + 1, offset + 2, offset + 3, offset + 4
    a, b, c, d = a or 0, b or 0, c or 0, d or 0  -- Handle nil values
    @position = offset + 4 unless offset != @position

    sign = d > 127 and -1 or 1
    exponent = (d % 128) * 2 + (c > 127 and 1 or 0)
    mantissa = a + b * 256 + (c % 128) * 256^2

    if exponent > 0 and exponent < 255
      sign * (1 + mantissa / 2^23) * 2^(exponent - 127)
    elseif exponent == 0
      sign * mantissa / 2^23 * 2^(-126) -- Subnormal numbers
    else
      mantissa == 0 and (sign * math.huge) or (0/0) -- Infinity or NaN

  -- Convert uint32 bits directly to float (optimized version)
  uint32_to_float: (u) =>
    a, b, c, d = u % 256, u % 65536, u % 16777216, u % 4294967296
    b, c, d = (b - a) / 256, (c - b) / 65536, (d - c) / 16777216

    sign = d > 127 and -1 or 1
    exponent = (d % 128) * 2 + (c > 127 and 1 or 0)
    mantissa = a + b * 256 + (c % 128) * 256^2

    if exponent > 0 and exponent < 255
      sign * (1 + mantissa / 2^23) * 2^(exponent - 127)
    elseif exponent == 0
      sign * mantissa / 2^23 * 2^(-126)
    else
      mantissa == 0 and (sign * math.huge) or (0/0)

  -- String reading with null termination
  read_cstring: (offset = @position) =>
    start_pos = offset + 1
    null_pos = @data\find '\0', start_pos

    unless null_pos
      error "BinaryReader: null-terminated string not found"

    value = @data\sub start_pos, null_pos - 1
    @position = null_pos unless offset != @position
    value

  -- Read string with specific length
  read_string: (length, offset = @position) =>
    @_check_bounds length
    value = @data\sub offset + 1, offset + length
    @position = offset + length unless offset != @position
    value

  -- Utility method for reading arrays
  read_array: (reader_func, count, offset = @position) =>
    [reader_func @ for i = 1, count]

  -- Cache management for performance
  cache_value: (key, value) =>
    @_cache[key] = value
    value

  get_cached: (key) =>
    @_cache[key]

  clear_cache: =>
    @_cache = {}
    @

BinaryReader