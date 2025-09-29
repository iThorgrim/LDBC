#!/usr/bin/env moon

-- Example: Reading Item.dbc from World of Warcraft TLK
-- This demonstrates reading real WoW item data

dbc = require "src.init"

-- Item.dbc schema for WoW:TLK (8 fields total)
ITEM_SCHEMA = {
  {name: "id", type: "uint", offset: 0}                    -- Item ID
  {name: "class", type: "uint", offset: 4}                -- Item class (weapon, armor, etc.)
  {name: "subclass", type: "uint", offset: 8}             -- Item subclass
  {name: "sound_override", type: "int", offset: 12}       -- Sound override (-1 if none)
  {name: "material", type: "uint", offset: 16}            -- Material type
  {name: "display_id", type: "uint", offset: 20}          -- Display info ID
  {name: "inventory_type", type: "uint", offset: 24}      -- Inventory slot type
  {name: "sheath_type", type: "uint", offset: 28}         -- How weapon is sheathed
}

-- Item class constants
ITEM_CLASSES = {
  [0]: "Consumable"
  [1]: "Container"
  [2]: "Weapon"
  [3]: "Gem"
  [4]: "Armor"
  [5]: "Reagent"
  [6]: "Projectile"
  [7]: "Trade Goods"
  [8]: "Generic"
  [9]: "Recipe"
  [10]: "Money"
  [11]: "Quiver"
  [12]: "Quest"
  [13]: "Key"
  [14]: "Permanent"
  [15]: "Miscellaneous"
  [16]: "Glyph"
}

-- Inventory type constants
INVENTORY_TYPES = {
  [0]: "None"
  [1]: "Head"
  [2]: "Neck"
  [3]: "Shoulder"
  [4]: "Body"
  [5]: "Chest"
  [6]: "Waist"
  [7]: "Legs"
  [8]: "Feet"
  [9]: "Wrists"
  [10]: "Hands"
  [11]: "Finger"
  [12]: "Trinket"
  [13]: "Weapon"
  [14]: "Shield"
  [15]: "Ranged"
  [16]: "Back"
  [17]: "Two-Hand"
  [18]: "Bag"
  [19]: "Tabard"
  [20]: "Robe"
  [21]: "Main Hand"
  [22]: "Off Hand"
  [23]: "Holdable"
  [24]: "Ammo"
  [25]: "Thrown"
  [26]: "Ranged Right"
  [27]: "Quiver"
  [28]: "Relic"
}

read_item_dbc = (file_path) ->
  unless dbc.validate file_path
    error "Invalid or missing Item.dbc file: #{file_path}"

  print "=== Reading Item.dbc ==="

  reader = dbc.open file_path
  reader\set_field_schema ITEM_SCHEMA

  -- Get basic info
  info = reader\get_file_info!
  print "Records: #{info.record_count}"
  print "Fields: #{info.field_count}"
  print "File size: #{math.floor(info.file_size / 1024)} KB"

  print "\n=== Sample Items ==="

  -- Show first 10 items
  for i = 0, math.min(9, reader\get_record_count! - 1)
    record = reader\get_record i

    id = record\get_field "id"
    class_id = record\get_field "class"
    subclass = record\get_field "subclass"
    material = record\get_field "material"
    display_id = record\get_field "display_id"
    inventory_type_id = record\get_field "inventory_type"

    class_name = ITEM_CLASSES[class_id] or "Unknown"
    inventory_type = INVENTORY_TYPES[inventory_type_id] or "Unknown"

    print "Item #{id}:"
    print "  Class: #{class_name} (#{class_id}.#{subclass})"
    print "  Inventory Type: #{inventory_type}"
    print "  Display ID: #{display_id}"
    print "  Material: #{material}"

  print "\n=== Item Analysis ==="

  -- Count items by class
  class_counts = {}
  inventory_counts = {}

  for record in reader\records!
    class_id = record\get_field "class"
    inventory_type_id = record\get_field "inventory_type"

    class_counts[class_id] = (class_counts[class_id] or 0) + 1
    inventory_counts[inventory_type_id] = (inventory_counts[inventory_type_id] or 0) + 1

  print "Items by Class:"
  for class_id, count in pairs class_counts
    class_name = ITEM_CLASSES[class_id] or "Unknown"
    print "  #{class_name}: #{count}"

  print "\nTop Inventory Types:"
  -- Sort by count and show top 10
  inventory_sorted = {}
  for type_id, count in pairs inventory_counts
    inventory_sorted[#inventory_sorted + 1] = {type_id, count}

  table.sort inventory_sorted, (a, b) -> a[2] > b[2]

  for i = 1, math.min(10, #inventory_sorted)
    type_id, count = inventory_sorted[i][1], inventory_sorted[i][2]
    type_name = INVENTORY_TYPES[type_id] or "Unknown"
    print "  #{type_name}: #{count}"

  -- Find specific interesting items
  print "\n=== Interesting Items ==="

  -- Find legendary items (usually have high display IDs)
  legendaries = reader\find_records (record) ->
    display_id = record\get_field "display_id"
    class_id = record\get_field "class"
    type(display_id) == "number" and display_id > 50000 and class_id == 2  -- Weapons

  print "Potential Legendary Weapons (high display ID):"
  for i = 1, math.min(5, #legendaries)
    record = legendaries[i]
    id = record\get_field "id"
    display_id = record\get_field "display_id"
    print "  Item #{id} (Display: #{display_id})"

  print "\n=== Stats ==="
  print "Total items analyzed: #{reader\get_record_count!}"

  reader\close!

-- Example usage
if arg and arg[1]
  item_file = arg[1]
  print "Reading Item.dbc from: #{item_file}"
  read_item_dbc item_file
else
  print "Usage: moon item_reader.moon /path/to/Item.dbc"
  print ""
  print "Example with typical WoW client installation:"
  print "  moon item_reader.moon \"C:/Program Files (x86)/World of Warcraft/Data/enUS/DBFilesClient/Item.dbc\""