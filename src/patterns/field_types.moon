-- FieldTypes: Strategy Pattern implementation for different field types
-- Handles the various data types found in DBC files

-- Abstract base class for field type strategies
class FieldType
  @TYPE_ID = "unknown"

  new: (size = 4) =>
    @size = size

  -- Abstract methods that must be implemented by subclasses
  read: (reader, offset, string_reader) =>
    error "FieldType.read must be implemented by subclass"

  guess_type: (reader, offset, string_reader) =>
    error "FieldType.guess_type must be implemented by subclass"

  get_size: => @size
  get_type_id: => @@TYPE_ID

-- Unsigned Integer field type
class UIntFieldType extends FieldType
  @TYPE_ID = "uint"

  new: (size = 4) =>
    super size
    assert size == 1 or size == 2 or size == 4, "Invalid uint size: #{size}"

  read: (reader, offset, string_reader) =>
    switch @size
      when 1 then reader\read_uint8 offset
      when 2 then reader\read_uint16_le offset
      when 4 then reader\read_uint32_le offset

  guess_type: (reader, offset, string_reader) =>
    value = @read reader, offset, string_reader
    -- UInt is likely if value is reasonable and non-negative
    if value >= 0 and value < 2^31
      0.8 -- High confidence
    elseif value >= 0
      0.4 -- Lower confidence for very large values
    else
      0.1 -- Very low confidence for "negative" values (due to overflow)

-- Signed Integer field type
class IntFieldType extends FieldType
  @TYPE_ID = "int"

  new: (size = 4) =>
    super size
    assert size == 1 or size == 2 or size == 4, "Invalid int size: #{size}"

  read: (reader, offset, string_reader) =>
    switch @size
      when 1 then reader\read_int8 offset
      when 2 then reader\read_int16_le offset
      when 4 then reader\read_int32_le offset

  guess_type: (reader, offset, string_reader) =>
    value = @read reader, offset, string_reader
    -- Int is more likely if we have negative values or small positive values
    if value < 0
      0.9 -- High confidence for negative values
    elseif value >= 0 and value < 65536
      0.6 -- Medium confidence for small positives
    else
      0.3 -- Lower confidence for large positives

-- Float field type
class FloatFieldType extends FieldType
  @TYPE_ID = "float"

  new: =>
    super 4 -- Floats are always 4 bytes in DBC

  read: (reader, offset, string_reader) =>
    reader\read_float32_le offset

  guess_type: (reader, offset, string_reader) =>
    -- Read as both uint and float to compare
    uint_value = reader\read_uint32_le offset
    float_value = reader\read_float32_le offset

    -- Float is likely if:
    -- 1. The float value is reasonable (not NaN, not huge)
    -- 2. The float interpretation makes more sense than uint
    if float_value != float_value -- NaN check
      return 0.1

    abs_float = math.abs float_value
    if abs_float > 1e-7 and abs_float < 1e6 and uint_value > 1000
      0.7 -- High confidence for reasonable float values
    elseif abs_float == 0
      0.5 -- Medium confidence for zero
    else
      0.2 -- Low confidence otherwise

-- String field type (references into string block)
class StringFieldType extends FieldType
  @TYPE_ID = "string"

  new: =>
    super 4 -- String references are always 4 bytes

  read: (reader, offset, string_reader) =>
    string_offset = reader\read_uint32_le offset
    if string_reader and string_offset > 0
      string_reader string_offset
    else
      "" -- Return empty string for null references

  guess_type: (reader, offset, string_reader) =>
    string_offset = reader\read_uint32_le offset

    unless string_reader
      return 0.1 -- Can't verify without string reader

    -- String is likely if:
    -- 1. Offset is 0 (null string)
    -- 2. Offset points to valid string in string block
    if string_offset == 0
      return 0.6 -- Medium confidence for null string

    string_value = string_reader string_offset
    if string_value and #string_value > 0
      -- Check if string contains reasonable characters
      if string_value\match "^[%w%s%p]*$"
        0.8 -- High confidence for valid strings
      else
        0.3 -- Lower confidence for strings with unusual characters
    else
      0.2 -- Low confidence if string reading failed

-- Boolean field type (special case of UInt8)
class BoolFieldType extends UIntFieldType
  @TYPE_ID = "bool"

  new: =>
    super 1

  read: (reader, offset, string_reader) =>
    value = super reader, offset, string_reader
    value != 0

  guess_type: (reader, offset, string_reader) =>
    value = reader\read_uint8 offset
    -- Bool is likely for 0/1 values in single bytes
    if value == 0 or value == 1
      0.9
    else
      0.1

-- Field type registry and factory
class FieldTypeRegistry
  new: =>
    @types = {}
    @default_sizes = {
      uint: 4, int: 4, float: 4, string: 4, bool: 1
    }
    @_register_default_types!

  _register_default_types: =>
    @register UIntFieldType
    @register IntFieldType
    @register FloatFieldType
    @register StringFieldType
    @register BoolFieldType

  register: (field_type_class) =>
    @types[field_type_class.TYPE_ID] = field_type_class

  create: (type_id, size) =>
    type_class = @types[type_id]
    error "Unknown field type: #{type_id}" unless type_class

    size or= @default_sizes[type_id] or 4
    type_class size

  -- Auto-detect field type based on data analysis
  guess_field_type: (reader, offset, string_reader, samples = 10) =>
    scores = {}

    -- Initialize scores for all registered types
    for type_id in pairs @types
      scores[type_id] = 0

    -- Analyze multiple samples to get better type detection
    sample_count = math.min samples, 10
    for i = 0, sample_count - 1
      current_offset = offset + i * 4 -- Assume 4-byte stride for sampling

      for type_id in pairs @types
        field_type = @create type_id
        score = field_type\guess_type reader, current_offset, string_reader
        scores[type_id] += score

    -- Find the type with the highest average score
    best_type, best_score = nil, -1
    for type_id, total_score in pairs scores
      avg_score = total_score / sample_count
      if avg_score > best_score
        best_type, best_score = type_id, avg_score

    best_type or "uint" -- Default to uint if no clear winner

-- Export singleton registry
registry = FieldTypeRegistry!

{
  :FieldType, :UIntFieldType, :IntFieldType, :FloatFieldType,
  :StringFieldType, :BoolFieldType, :FieldTypeRegistry,
  :registry
}