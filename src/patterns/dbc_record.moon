-- DbcRecord: Builder pattern implementation for DBC record construction
-- Provides flexible record building with field validation and type conversion

import registry from require "src.patterns.field_types"

class DbcRecord
  new: (record_index = 0) =>
    @record_index = record_index
    @fields = {}
    @field_names = {}
    @field_types = {}
    @_built = false

  -- Builder methods for setting up the record structure
  add_field: (name, type_id, value = nil) =>
    assert not @_built, "Cannot modify record after it has been built"
    assert type(name) == "string", "Field name must be a string"

    index = #@field_names + 1
    @field_names[index] = name
    @field_types[name] = type_id
    @fields[name] = value
    @fields[index] = value  -- Also store by index for fast access
    @

  set_field: (name, value) =>
    assert not @_built, "Cannot modify record after it has been built"
    assert @fields[name] ~= nil, "Field '#{name}' does not exist"

    @fields[name] = value
    -- Update indexed access as well
    for i, field_name in ipairs @field_names
      if field_name == name
        @fields[i] = value
        break
    @

  set_field_by_index: (index, value) =>
    assert not @_built, "Cannot modify record after it has been built"
    assert index > 0 and index <= #@field_names, "Field index #{index} out of bounds"

    field_name = @field_names[index]
    @fields[field_name] = value
    @fields[index] = value
    @

  -- Build the record and make it immutable
  build: =>
    @_built = true
    @

  -- Field access methods
  get_field: (name) =>
    @fields[name]

  get_field_by_index: (index) =>
    @fields[index]

  get_field_type: (name) =>
    @field_types[name]

  get_field_count: =>
    #@field_names

  get_field_names: =>
    [name for name in *@field_names]

  has_field: (name) =>
    @fields[name] ~= nil

  -- Record information
  get_record_index: =>
    @record_index

  is_built: =>
    @_built

  -- Iteration support
  pairs: =>
    next_func = (t, k) ->
      if k == nil
        return @field_names[1], @fields[@field_names[1]]
      else
        for i = 1, #@field_names - 1
          if @field_names[i] == k
            next_name = @field_names[i + 1]
            return next_name, @fields[next_name]
        return nil

    next_func, @fields, nil

  -- Conversion utilities
  to_table: =>
    result = {}
    for name, value in @pairs!
      result[name] = value
    result.record_index = @record_index
    result

  to_array: =>
    [@fields[i] for i = 1, #@field_names]

  -- Validation
  validate: =>
    for i = 1, #@field_names
      name = @field_names[i]
      value = @fields[name]
      type_id = @field_types[name]

      -- Basic type validation
      switch type_id
        when "uint", "int"
          unless type(value) == "number" and value == math.floor(value)
            error "Field '#{name}' expected integer, got #{type(value)}: #{value}"
        when "float"
          unless type(value) == "number"
            error "Field '#{name}' expected number, got #{type(value)}: #{value}"
        when "string"
          unless type(value) == "string"
            error "Field '#{name}' expected string, got #{type(value)}: #{value}"
        when "bool"
          unless type(value) == "boolean"
            error "Field '#{name}' expected boolean, got #{type(value)}: #{value}"

    true

  -- String representation
  __tostring: =>
    if @_built
      fields_str = table.concat ["#{name}=#{@fields[name]}" for name in *@field_names], ", "
      "DbcRecord{index=#{@record_index}, #{fields_str}}"
    else
      "DbcRecord{index=#{@record_index}, fields=#{#@field_names}, unbuilt}"

-- Factory class for creating records from binary data
class DbcRecordBuilder
  new: (header, field_schema) =>
    @header = header
    @field_schema = field_schema or @_guess_field_schema!
    @string_reader = (offset) -> @header\read_string_at_offset offset

  _guess_field_schema: =>
    -- Simple schema guessing - assumes all fields are 4-byte uints
    -- This can be overridden with actual schema information
    schema = {}
    field_count = @header\get_field_count!
    record_size = @header\get_record_size!
    field_size = record_size / field_count

    for i = 1, field_count
      schema[i] = {
        name: "field#{i}"
        type: field_size == 4 and "uint" or "uint"
        offset: (i - 1) * field_size
        size: field_size
      }

    schema

  -- Build a record from binary data at specific offset
  build_record: (reader, record_offset, record_index) =>
    record = DbcRecord record_index

    for i, field_info in ipairs @field_schema
      field_offset = record_offset + field_info.offset
      field_type = registry\create field_info.type, field_info.size

      -- Read the field value
      value = field_type\read reader, field_offset, @string_reader

      -- Add field to record
      record\add_field field_info.name, field_info.type, value

    record\validate!
    record\build!

  -- Auto-detect field types from data samples
  auto_detect_schema: (reader, sample_size = 10) =>
    field_count = @header\get_field_count!
    record_size = @header\get_record_size!
    field_size = record_size / field_count

    schema = {}
    records_start = @header\get_records_start!

    for field_idx = 1, field_count
      field_offset = (field_idx - 1) * field_size

      -- Sample multiple records to detect field type
      sample_offsets = {}
      for sample = 0, math.min(sample_size - 1, @header\get_record_count! - 1)
        sample_offsets[#sample_offsets + 1] = records_start + sample * record_size + field_offset

      -- Use registry to guess the best field type
      detected_type = registry\guess_field_type reader, sample_offsets[1], @string_reader, #sample_offsets

      schema[field_idx] = {
        name: "field#{field_idx}"
        type: detected_type
        offset: field_offset
        size: field_size
      }

    @field_schema = schema
    schema

  -- Batch build records with optional lazy loading
  build_records: (reader, start_index = 0, count = nil, lazy = false) =>
    count or= @header\get_record_count! - start_index
    count = math.min count, @header\get_record_count! - start_index

    records = {}
    records_start = @header\get_records_start!
    record_size = @header\get_record_size!

    for i = 0, count - 1
      record_index = start_index + i
      record_offset = records_start + record_index * record_size

      if lazy
        -- Store building function for lazy evaluation
        records[record_index + 1] = -> @build_record reader, record_offset, record_index
      else
        -- Build record immediately
        records[record_index + 1] = @build_record reader, record_offset, record_index

    records

  -- Get field schema information
  get_field_schema: =>
    @field_schema

  set_field_schema: (schema) =>
    @field_schema = schema
    @

{:DbcRecord, :DbcRecordBuilder}