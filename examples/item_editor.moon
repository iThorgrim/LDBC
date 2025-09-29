#!/usr/bin/env moon

-- Example: Item.dbc editor with DBC writer
-- Demonstrates both reading and writing Item.dbc files

dbc = require "src.init"

-- Item.dbc schema for WoW:TLK (8 fields total)
ITEM_SCHEMA = {
  {name: "id", type: "uint", offset: 0}
  {name: "class", type: "uint", offset: 4}
  {name: "subclass", type: "uint", offset: 8}
  {name: "sound_override", type: "int", offset: 12}
  {name: "material", type: "uint", offset: 16}
  {name: "display_id", type: "uint", offset: 20}
  {name: "inventory_type", type: "uint", offset: 24}
  {name: "sheath_type", type: "uint", offset: 28}
}

ITEM_CLASSES = {
  [0]: "Consumable", [1]: "Container", [2]: "Weapon", [3]: "Gem",
  [4]: "Armor", [5]: "Reagent", [6]: "Projectile", [7]: "Trade Goods",
  [8]: "Generic", [9]: "Recipe", [10]: "Money", [11]: "Quiver",
  [12]: "Quest", [13]: "Key", [14]: "Permanent", [15]: "Miscellaneous", [16]: "Glyph"
}

edit_item_dbc = (input_path, output_path) ->
  unless dbc.validate input_path
    error "Invalid or missing Item.dbc file: #{input_path}"

  print "=== Reading and Editing #{input_path} ==="

  -- Open for editing
  writer = dbc.open_for_edit input_path, {field_schema: ITEM_SCHEMA}

  stats = writer\get_statistics!
  print "Original records: #{stats.original_records}"

  print "\n=== Sample modifications ==="

  -- 1. Show first few items before modification
  print "First 3 items before modification:"
  for i = 0, 2
    record = writer\get_record i
    id = record\get_field "id"
    class_id = record\get_field "class"
    display_id = record\get_field "display_id"
    class_name = ITEM_CLASSES[class_id] or "Unknown"
    print "  Item #{id}: #{class_name}, Display #{display_id}"

  -- 2. Modify display IDs
  print "\nModifying display IDs for first 3 items..."
  for i = 0, 2
    new_display = 50000 + i
    writer\update_field i, "display_id", new_display
    print "  Item #{i}: Display ID → #{new_display}"

  -- 3. Add a custom item
  print "\nAdding custom item..."
  custom_record = dbc.DbcRecord 999999
  custom_record\add_field "id", 999999
  custom_record\add_field "class", 15  -- Miscellaneous
  custom_record\add_field "subclass", 0
  custom_record\add_field "sound_override", -1
  custom_record\add_field "material", 0
  custom_record\add_field "display_id", 99999
  custom_record\add_field "inventory_type", 0
  custom_record\add_field "sheath_type", 0

  new_index = writer\add_record custom_record
  print "  Added custom item at index #{new_index}"

  -- 4. Bulk modification: Change all consumables to display_id 88888
  print "\nBulk modification: Updating consumable display IDs..."
  consumable_count = writer\update_records(
    (record) -> record\get_field("class") == 0,  -- Consumables
    (record) ->
      new_record = dbc.DbcRecord record\get_record_index!
      for field_name in *record\get_field_names!
        value = record\get_field field_name
        if field_name == "display_id"
          value = 88888
        new_record\add_field field_name, value
      new_record
  )
  print "  Modified #{consumable_count} consumable items"

  print "\n=== Validation and Save ==="

  -- Validate
  is_valid, errors = writer\validate!
  if is_valid
    print "✓ All modifications are valid"
  else
    print "✗ Validation errors:"
    for error in *errors
      print "  - #{error}"
    return

  -- Save
  writer\save_as output_path
  final_stats = writer\get_statistics!

  print "✓ Saved to #{output_path}"
  print "  Final record count: #{final_stats.current_records}"
  print "  Added: #{final_stats.added}"

  writer\close!

  print "\n=== Verification ==="

  -- Verify the saved file
  verify_reader = dbc.open output_path, {field_schema: ITEM_SCHEMA}
  verify_info = verify_reader\get_file_info!

  print "Verification:"
  print "  Records: #{verify_info.record_count}"
  print "  File size: #{math.floor(verify_info.file_size / 1024)} KB"

  -- Check our modifications
  print "\nVerifying modifications:"
  for i = 0, 2
    record = verify_reader\get_record i
    display_id = record\get_field "display_id"
    expected = 50000 + i
    if display_id == expected
      print "  ✓ Item #{i}: Display ID = #{display_id}"
    else
      print "  ✗ Item #{i}: Expected #{expected}, got #{display_id}"

  verify_reader\close!

-- Example usage
if arg and arg[1]
  input_file = arg[1]
  output_file = arg[2] or input_file\gsub("%.dbc$", "_edited.dbc")

  print "Item.dbc Editor"
  print "Input: #{input_file}"
  print "Output: #{output_file}"

  success, error_msg = pcall -> edit_item_dbc input_file, output_file

  if success
    print "\n🎉 Item editing completed successfully!"
  else
    print "\n❌ Error: #{error_msg}"
else
  print "Usage: moon item_editor.moon input.dbc [output.dbc]"
  print "Example: moon item_editor.moon Item.dbc Item_modified.dbc"