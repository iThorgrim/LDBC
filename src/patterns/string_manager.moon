-- StringManager: Handles string block optimization and management
-- Implements deduplication and offset management for DBC string blocks

class StringManager
  new: =>
    @strings = {} -- string -> offset mapping
    @block_data = "\0" -- Always start with null
    @next_offset = 1

  add_string: (str) =>
    return 0 if not str or #str == 0

    -- Check if string already exists (deduplication)
    if @strings[str]
      return @strings[str]

    -- Add new string
    offset = @next_offset
    @strings[str] = offset
    @block_data ..= str .. "\0"
    @next_offset += #str + 1

    offset

  get_string_block: =>
    @block_data

  get_block_size: =>
    #@block_data

  get_string_count: =>
    count = 0
    for _ in pairs @strings
      count += 1
    count

  clear: =>
    @strings = {}
    @block_data = "\0"
    @next_offset = 1
    @

  has_string: (str) =>
    @strings[str] ~= nil

  get_offset: (str) =>
    @strings[str] or 0

  -- Debug utilities
  list_strings: =>
    result = {}
    for str, offset in pairs @strings
      result[#result + 1] = {string: str, offset: offset}
    table.sort result, (a, b) -> a.offset < b.offset
    result

  get_statistics: =>
    {
      string_count: @get_string_count!
      block_size: @get_block_size!
      average_length: @get_string_count! > 0 and (@get_block_size! - 1) / @get_string_count! or 0
    }

StringManager