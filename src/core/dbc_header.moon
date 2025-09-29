-- DbcHeader: DBC file header parsing and validation
-- Based on WDBC format for WoW:TLK

BinaryReader = require "src.io.binary_reader"

class DbcHeader
  -- DBC Header structure (20 bytes):
  -- 4 bytes: fourCC ("WDBC")
  -- 4 bytes: record count
  -- 4 bytes: field count
  -- 4 bytes: record size
  -- 4 bytes: string block size

  @FOURCC = "WDBC"
  @HEADER_SIZE = 20
  @MIN_FIELD_COUNT = 1
  @MAX_FIELD_COUNT = 256
  @MIN_RECORD_SIZE = 4
  @MAX_RECORD_SIZE = 2048

  new: (data) =>
    @reader = BinaryReader data
    @_parse_header!
    @_validate!

  _parse_header: =>
    @reader\seek 0

    -- Read and validate fourCC
    @fourcc = @reader\read_string 4
    unless @fourcc == @@FOURCC
      error "Invalid DBC file: expected fourCC '#{@@FOURCC}', got '#{@fourcc}'"

    -- Read header fields
    @record_count = @reader\read_uint32_le!
    @field_count = @reader\read_uint32_le!
    @record_size = @reader\read_uint32_le!
    @string_block_size = @reader\read_uint32_le!

    -- Calculate derived values
    @records_start = @@HEADER_SIZE
    @records_size = @record_count * @record_size
    @string_block_start = @records_start + @records_size
    @total_size = @string_block_start + @string_block_size

  _validate: =>
    data_size = @reader.length

    -- Validate field count
    unless @field_count >= @@MIN_FIELD_COUNT and @field_count <= @@MAX_FIELD_COUNT
      error "Invalid field count: #{@field_count} (expected #{@@MIN_FIELD_COUNT}-#{@@MAX_FIELD_COUNT})"

    -- Validate record size
    unless @record_size >= @@MIN_RECORD_SIZE and @record_size <= @@MAX_RECORD_SIZE
      error "Invalid record size: #{@record_size} (expected #{@@MIN_RECORD_SIZE}-#{@@MAX_RECORD_SIZE})"

    -- Check if record size is multiple of 4 (DBC alignment requirement)
    unless @record_size % 4 == 0
      error "Invalid record size: #{@record_size} (must be multiple of 4)"

    -- Validate data size
    unless data_size >= @total_size
      error "DBC data too short: expected #{@total_size} bytes, got #{data_size}"

    -- Validate string block
    unless @string_block_size >= 0
      error "Invalid string block size: #{@string_block_size}"

    -- Additional validation: first byte of string block should be null
    if @string_block_size > 0
      first_string_byte = @reader\read_uint8 @string_block_start
      unless first_string_byte == 0
        error "Invalid string block: first byte should be null terminator"

  -- Getters for header information
  get_record_count: => @record_count
  get_field_count: => @field_count
  get_record_size: => @record_size
  get_string_block_size: => @string_block_size
  get_records_start: => @records_start
  get_string_block_start: => @string_block_start
  get_total_size: => @total_size

  -- Check if file has records
  has_records: => @record_count > 0

  -- Check if file has string block
  has_string_block: => @string_block_size > 0

  -- Get record offset by index (0-based)
  get_record_offset: (index) =>
    assert index >= 0 and index < @record_count, "Record index out of bounds: #{index}"
    @records_start + (index * @record_size)

  -- String block utilities
  read_string_at_offset: (offset) =>
    if offset == 0 or offset >= @string_block_size
      return ""

    string_pos = @string_block_start + offset
    @reader\read_cstring string_pos

  -- Validation helper for external use
  validate_record_index: (index) =>
    unless index >= 0 and index < @record_count
      error "Record index out of bounds: #{index} (valid range: 0-#{@record_count-1})"
    true

  validate_field_index: (index) =>
    unless index >= 0 and index < @field_count
      error "Field index out of bounds: #{index} (valid range: 0-#{@field_count-1})"
    true

  -- Debug information
  to_string: =>
    "DbcHeader{fourcc=#{@fourcc}, records=#{@record_count}, fields=#{@field_count}, " ..
    "record_size=#{@record_size}, string_size=#{@string_block_size}, total=#{@total_size}}"

  -- Static factory method for validation without instantiation
  @validate_data: (data) ->
    return false unless type(data) == "string"
    return false unless #data >= DbcHeader.HEADER_SIZE
    return false unless data\sub(1, 4) == DbcHeader.FOURCC
    true

DbcHeader