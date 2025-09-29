-- DbcReader: Main DBC file reader using Template Method pattern
-- Provides high-level interface for reading DBC files with caching and optimization

lfs = require "lfs"
BinaryReader = require "src.io.binary_reader"
DbcHeader = require "src.core.dbc_header"
import DbcRecordBuilder from require "src.patterns.dbc_record"

class DbcReader
  -- Template Method pattern: defines the algorithm structure
  -- Subclasses can override specific steps for customization

  @VERSION = "1.0.0"

  new: (file_path, options = {}) =>
    @file_path = file_path
    @options = {
      lazy_loading: options.lazy_loading != false -- Default to true
      auto_detect_schema: options.auto_detect_schema != false -- Default to true
    }

    @data = nil
    @header = nil
    @record_builder = nil
    @_initialized = false

  -- Template Method: Main algorithm for opening and reading DBC files
  open: (file_path) =>
    file_path or= @file_path
    assert file_path, "No file path specified"

    -- Template method steps:
    @_validate_file file_path
    @_load_data file_path
    @_parse_header!
    @_setup_record_builder!
    @_post_initialize!

    @_initialized = true
    @

  -- Template Method steps (can be overridden by subclasses)
  _validate_file: (file_path) =>
    -- Check if file exists
    file_info = lfs.attributes file_path
    unless file_info
      error "File not found: #{file_path}"

    -- Check if it's a regular file
    unless file_info.mode == "file"
      error "Path is not a file: #{file_path}"

    -- Check file size
    if file_info.size < DbcHeader.HEADER_SIZE
      error "File too small to be a valid DBC file: #{file_path}"

    @file_path = file_path
    @file_size = file_info.size

  _load_data: (file_path) =>
    file = io.open file_path, "rb"
    unless file
      error "Cannot open file: #{file_path}"

    @data = file\read "*all"
    file\close!

    unless #@data >= DbcHeader.HEADER_SIZE
      error "Failed to read DBC file data"

    -- Quick validation of DBC format
    unless DbcHeader.validate_data @data
      error "Invalid DBC file format"

  _parse_header: =>
    @header = DbcHeader @data
    @reader = BinaryReader @data


  _setup_record_builder: =>
    @record_builder = DbcRecordBuilder @header

    -- Auto-detect field schema if enabled
    if @options.auto_detect_schema
      @record_builder\auto_detect_schema @reader

  _post_initialize: =>
    -- Hook for subclasses to perform additional initialization
    if @options.preload_strings and @header\has_string_block!
      @_preload_string_block!

  -- String block preloading for performance
  _preload_string_block: =>
    @_string_cache = {}
    string_size = @header\get_string_block_size!

    if string_size > 0
      -- Parse entire string block
      current_offset = 0
      while current_offset < string_size
        string_value = @header\read_string_at_offset current_offset
        if string_value and #string_value > 0
          @_string_cache[current_offset] = string_value
          current_offset += #string_value + 1 -- +1 for null terminator
        else
          current_offset += 1

  -- Record access methods
  get_record: (index) =>
    @_ensure_initialized!
    @header\validate_record_index index

    -- Build record directly
    record_offset = @header\get_record_offset index
    @record_builder\build_record @reader, record_offset, index

  get_record_count: =>
    @_ensure_initialized!
    @header\get_record_count!

  get_field_count: =>
    @_ensure_initialized!
    @header\get_field_count!

  -- Batch record operations
  get_records: (start_index = 0, count = nil) =>
    @_ensure_initialized!
    count or= @get_record_count! - start_index
    count = math.min count, @get_record_count! - start_index

    records = {}
    for i = 0, count - 1
      records[i + 1] = @get_record start_index + i

    records

  -- Lazy loading support
  get_records_lazy: (start_index = 0, count = nil) =>
    @_ensure_initialized!
    count or= @get_record_count! - start_index

    @record_builder\build_records @reader, start_index, count, true

  -- Iterator support for easy traversal
  records: =>
    @_ensure_initialized!
    index = -1
    count = @get_record_count!

    ->
      index += 1
      if index < count
        @get_record index
      else
        nil

  -- Search and filtering
  find_records: (predicate) =>
    @_ensure_initialized!
    results = {}

    for record in @records!
      if predicate record
        results[#results + 1] = record

    results

  find_record: (predicate) =>
    @_ensure_initialized!
    for record in @records!
      if predicate record
        return record
    nil

  -- Schema information
  get_field_schema: =>
    @_ensure_initialized!
    @record_builder\get_field_schema!

  set_field_schema: (schema) =>
    @_ensure_initialized!
    @record_builder\set_field_schema schema
    @


  -- File information
  get_file_info: =>
    {
      file_path: @file_path
      file_size: @file_size
      record_count: @get_record_count!
      field_count: @get_field_count!
      string_block_size: @header\get_string_block_size!
      has_string_block: @header\has_string_block!
    }

  -- Debug and diagnostics
  validate_all_records: =>
    @_ensure_initialized!
    errors = {}

    for i = 0, @get_record_count! - 1
      success, err = pcall -> @get_record i
      unless success
        errors[#errors + 1] = {index: i, error: err}

    errors

  -- Cleanup
  close: =>
    @data = nil
    @reader = nil
    @header = nil
    @record_builder = nil
    @_initialized = false

  -- Private methods
  _ensure_initialized: =>
    unless @_initialized
      error "DbcReader not initialized. Call open() first."

  -- Static factory methods
  @open: (file_path, options = {}) ->
    reader = DbcReader file_path, options
    reader\open!
    reader

  @validate_file: (file_path) ->
    success = pcall ->
      reader = DbcReader file_path
      reader\_validate_file file_path
      reader\_load_data file_path
      reader\_parse_header!

    success

  -- String representation
  __tostring: =>
    if @_initialized
      info = @get_file_info!
      "DbcReader{file=#{info.file_path}, records=#{info.record_count}, fields=#{info.field_count}}"
    else
      "DbcReader{uninitialized}"

DbcReader