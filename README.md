# TLK-DBC: World of Warcraft TLK DBC Reader/Writer

A modern, object-oriented DBC file reader and writer for World of Warcraft: The Lich King, built with Moonscript using clean architecture and various Design Pattern.

> [!IMPORTANT]
> The primary goal was to try to create a DBC Reader/Writer in Lua while using several different design patterns for learning purposes.
> Some design patterns may therefore be misused.

## Features

### 📖 **Reading**
- DBC file parsing
- Auto-detection of field types
- Custom schema support

### ✏️ **Writing**
- Full DBC file modification support
- String block optimization with deduplication
- Bulk operations with predicates
- Data integrity validation

### 🏗️ **Architecture**
- **Modular Design**: Clean separation of concerns
- **Design Patterns**: Strategy, Builder, Template Method patterns
- **Object-Oriented**: Proper encapsulation and inheritance

## Project Structure

```
src/
├── core/                   # Core DBC functionality
│   ├── dbc_reader.moon     # Main reader class
│   ├── dbc_writer.moon     # Main writer class
│   └── dbc_header.moon     # Header parsing
├── io/                     # Binary I/O operations
│   ├── binary_reader.moon  # Binary data reading
│   └── binary_writer.moon  # Binary data writing
├── patterns/               # Design pattern implementations
│   ├── dbc_record.moon     # Record builder
│   ├── field_types.moon    # Field type strategies
│   └── string_manager.moon # String Manager
└── init.moon               # Main module interface
```

## Usage

### Reading DBC Files

```moonscript
dbc = require "tlkdbc"

-- Simple reading
reader = dbc.open "Item.dbc"
record = reader\get_record 0
item_id = record\get_field "field1"
reader\close!

-- With custom schema
schema = {
  {name: "id", type: "uint", offset: 0}
  {name: "class", type: "uint", offset: 4}
  {name: "display_id", type: "uint", offset: 20}
}
reader = dbc.open "Item.dbc", {field_schema: schema}
```

```lua
local dbc = require("tlkdbc")

local reader = dbc.open("Item.dbc")
local record = reader:get_record(0)
local item_id = record:get_field("field1")

reader:close()

-- With custom schema
schema = {
  {name = "id", type = "uint", offset = 0}
  {name = "class", type = "uint", offset = 4}
  {name = "display_id", type = "uint", offset = 20}
}
local reader = dbc.open("Item.dbc", {field_schema = schema})
```

### Writing DBC Files

```moonscript
-- Open for editing
writer = dbc.open_for_edit "Item.dbc"

-- Modify a field
writer\update_field 0, "display_id", 99999

-- Bulk modifications
count = writer\update_records(
  (record) -> record\get_field("class") == 2,  -- Weapons
  (record) ->
    new_record = dbc.DbcRecord record\get_record_index!
    -- ... modify fields
    new_record
)

-- Add new record
new_record = dbc.DbcRecord 999999
new_record\add_field "id", 999999
new_record\add_field "class", 15
writer\add_record new_record

-- Save changes
writer\save_as "Item_modified.dbc"
writer\close!
```

```lua
-- Open for editing
local writer = dbc.open_for_edit("Item.dbc")

-- Modify a field
writer:update_field(0, "display_id", 99999)

-- Bulk modifications
local count = writer:update_records(
  function(record)
    return record:get_field("class") == 2
  end,  -- Weapons

  function(record)
    local new_record = dbc.DbcRecord(record:get_record_index())
    return new_record
  end
)

-- Add new record
local new_record = dbc.DbcRecord(999999)
new_record:add_field("id", 999999)
new_record:add_field("class", 15)
writer:add_record(new_record)

-- Save changes
writer:save_as("Item_modified.dbc")
writer:close()
```

## Examples

- `examples/item_reader.moon` - Reading Item.dbc with analysis
- `examples/item_editor.moon` - Editing Item.dbc with modifications
- `examples/achievement_reader.moon` - Reading Achievement.dbc with strings

## Design Patterns Used

- **Strategy Pattern**: Field type handling (`field_types.moon`)
- **Builder Pattern**: Record construction (`dbc_record.moon`)
- **Template Method**: DBC reconstruction (`dbc_writer.moon`)

The library is designed for internal project use with clean, maintainable code that's easy to extend and modify.