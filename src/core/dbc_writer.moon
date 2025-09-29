-- DbcWriter: DBC file writer with modification capabilities
-- Implements Template Method pattern for DBC file reconstruction

BinaryWriter = require "src.io.binary_writer"
StringManager = require "src.patterns.string_manager"
{DbcRecordBuilder} = require "src.patterns.dbc_record"

class DbcWriter
  new: (reader_or_path, options = {}) =>
    @options = options
    @modified = false

    if type(reader_or_path) == "string"
      -- Create from file path
      DbcReader = require "core.dbc_reader"
      @reader = DbcReader.open reader_or_path, options
      @file_path = reader_or_path
    else
      -- Use existing reader
      @reader = reader_or_path
      @file_path = @reader.file_path

    @records = {}
    @string_manager = StringManager!
    @_load_records!

  _load_records: =>
    -- Load all records into memory for modification
    for i = 0, @reader\get_record_count! - 1
      @records[i] = @reader\get_record i

  -- Record access and modification
  get_record: (index) =>
    @records[index]

  set_record: (index, record) =>
    @records[index] = record
    @modified = true
    @

  add_record: (record) =>
    max_index = -1
    for k in pairs @records
      if k > max_index
        max_index = k
    new_index = max_index + 1
    @records[new_index] = record
    @modified = true
    new_index

  remove_record: (index) =>
    @records[index] = nil
    @modified = true
    @

  -- Field modification helpers
  update_field: (record_index, field_name, value) =>
    record = @records[record_index]
    return false unless record

    -- Create new record with updated field
    {DbcRecord} = require "patterns.dbc_record"
    new_record = DbcRecord record\get_record_index!
    field_names = record\get_field_names!

    for name in *field_names
      field_value = name == field_name and value or record\get_field(name)
      new_record\add_field name, field_value

    @records[record_index] = new_record
    @modified = true
    true

  -- Bulk operations
  update_records: (predicate, updater) =>
    count = 0
    for index, record in pairs @records
      if predicate record
        updated_record = updater record
        if updated_record
          @records[index] = updated_record
          count += 1

    @modified = true if count > 0
    count

  -- Write operations
  save: (output_path = nil) =>
    output_path or= @file_path
    assert output_path, "No output path specified"

    @_rebuild_data!

    -- Write to file
    file = io.open output_path, "wb"
    unless file
      error "Cannot create output file: #{output_path}"

    file\write @data
    file\close!
    @modified = false
    @

  save_as: (output_path) =>
    @save output_path

  _rebuild_data: =>
    -- Template method for rebuilding DBC data
    @_prepare_strings!
    @_calculate_sizes!
    @_write_header!
    @_write_records!
    @_write_string_block!

  _prepare_strings: =>
    @string_manager\clear!
    schema = @reader.field_schema

    for index, record in pairs @records
      for field_info in *schema
        if field_info.type == "string"
          value = record\get_field field_info.name
          if value and #value > 0
            @string_manager\add_string value

  _calculate_sizes: =>
    record_indices = [k for k in pairs @records]
    table.sort record_indices

    @calculated = {
      record_count: #record_indices
      field_count: @reader\get_field_count!
      record_size: @reader.header\get_record_size!
      string_block_size: @string_manager\get_block_size!
      record_indices: record_indices
    }

  _write_header: =>
    @writer = BinaryWriter!
    @writer\write_string "WDBC"
    @writer\write_uint32_le @calculated.record_count
    @writer\write_uint32_le @calculated.field_count
    @writer\write_uint32_le @calculated.record_size
    @writer\write_uint32_le @calculated.string_block_size

  _write_records: =>
    schema = @reader.field_schema

    for _, index in ipairs @calculated.record_indices
      record = @records[index]
      record_pos = @writer\tell!

      for field_info in *schema
        field_value = record\get_field field_info.name

        switch field_info.type
          when "uint"
            @writer\write_uint32_le field_value or 0
          when "int"
            @writer\write_int32_le field_value or 0
          when "float"
            @writer\write_float32_le field_value or 0.0
          when "string"
            if field_value and #field_value > 0
              offset = @string_manager\get_offset field_value
              @writer\write_uint32_le offset
            else
              @writer\write_uint32_le 0
          else
            @writer\write_uint32_le field_value or 0

      -- Ensure record is correct size
      current_size = @writer\tell! - record_pos
      if current_size < @calculated.record_size
        for i = current_size + 1, @calculated.record_size
          @writer\write_uint8 0

  _write_string_block: =>
    string_block = @string_manager\get_string_block!
    @writer\write_string string_block
    @data = @writer\get_data!

  -- Utility methods
  is_modified: => @modified

  get_record_count: =>
    #[@k for k in pairs @records]

  get_statistics: =>
    record_count = @get_record_count!
    original_count = @reader\get_record_count!

    {
      original_records: original_count
      current_records: record_count
      added: math.max(0, record_count - original_count)
      removed: math.max(0, original_count - record_count)
      modified: @modified
      string_count: @string_manager\get_string_count!
      string_block_size: @string_manager\get_block_size!
    }

  -- Validation
  validate: =>
    errors = {}

    for index, record in pairs @records
      unless record
        errors[#errors + 1] = "Record #{index} is nil"
        continue

      field_names = record\get_field_names!
      expected_fields = #@reader.field_schema

      unless #field_names == expected_fields
        errors[#errors + 1] = "Record #{index} has #{#field_names} fields, expected #{expected_fields}"

    #errors == 0, errors

  close: =>
    @reader\close! if @reader
    @records = {}
    @string_manager = nil

  @open: (file_path, options = {}) ->
    DbcWriter file_path, options

DbcWriter