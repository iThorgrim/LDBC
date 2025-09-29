#!/usr/bin/env moon

-- Example: Reading Achievement.dbc from World of Warcraft TLK
-- This demonstrates reading achievement data with string references

dbc = require "src.init"

-- Achievement.dbc schema for WoW:TLK
ACHIEVEMENT_SCHEMA = {
  {name: "id", type: "uint", offset: 0}                           -- 1. Achievement ID
  {name: "faction", type: "int", offset: 4}                       -- 2. Faction (-1=both, 0=Horde, 1=Alliance)
  {name: "map_id", type: "int", offset: 8}                        -- 3. Map requirement (-1=any)
  {name: "previous", type: "uint", offset: 12}                    -- 4. Previous achievement in series
  -- 5-20: Name in different languages (16 fields)
  {name: "name_lang_1", type: "string", offset: 16}              -- 5. Name (English)
  {name: "name_lang_2", type: "string", offset: 20}              -- 6. Name (Korean)
  {name: "name_lang_3", type: "string", offset: 24}              -- 7. Name (French)
  {name: "name_lang_4", type: "string", offset: 28}              -- 8. Name (German)
  {name: "name_lang_5", type: "string", offset: 32}              -- 9. Name (Chinese)
  {name: "name_lang_6", type: "string", offset: 36}              -- 10. Name (Taiwanese)
  {name: "name_lang_7", type: "string", offset: 40}              -- 11. Name (Spanish Mexico)
  {name: "name_lang_8", type: "string", offset: 44}              -- 12. Name (Spanish)
  {name: "name_lang_9", type: "string", offset: 48}              -- 13. Name (Russian)
  {name: "name_lang_10", type: "string", offset: 52}             -- 14. Name (Portuguese)
  {name: "name_lang_11", type: "string", offset: 56}             -- 15. Name (Italian)
  {name: "name_lang_12", type: "string", offset: 60}             -- 16. Name (Unknown)
  {name: "name_lang_13", type: "string", offset: 64}             -- 17. Name (Unknown)
  {name: "name_lang_14", type: "string", offset: 68}             -- 18. Name (Unknown)
  {name: "name_lang_15", type: "string", offset: 72}             -- 19. Name (Unknown)
  {name: "name_lang_16", type: "string", offset: 76}             -- 20. Name (Unknown)
  {name: "name_flags", type: "uint", offset: 80}                 -- 21. Name flags (always 0xFF01FE)
  -- 22-37: Description in different languages (16 fields)
  {name: "desc_lang_1", type: "string", offset: 84}              -- 22. Description (English)
  {name: "desc_lang_2", type: "string", offset: 88}              -- 23. Description (Korean)
  {name: "desc_lang_3", type: "string", offset: 92}              -- 24. Description (French)
  {name: "desc_lang_4", type: "string", offset: 96}              -- 25. Description (German)
  {name: "desc_lang_5", type: "string", offset: 100}             -- 26. Description (Chinese)
  {name: "desc_lang_6", type: "string", offset: 104}             -- 27. Description (Taiwanese)
  {name: "desc_lang_7", type: "string", offset: 108}             -- 28. Description (Spanish Mexico)
  {name: "desc_lang_8", type: "string", offset: 112}             -- 29. Description (Spanish)
  {name: "desc_lang_9", type: "string", offset: 116}             -- 30. Description (Russian)
  {name: "desc_lang_10", type: "string", offset: 120}            -- 31. Description (Portuguese)
  {name: "desc_lang_11", type: "string", offset: 124}            -- 32. Description (Italian)
  {name: "desc_lang_12", type: "string", offset: 128}            -- 33. Description (Unknown)
  {name: "desc_lang_13", type: "string", offset: 132}            -- 34. Description (Unknown)
  {name: "desc_lang_14", type: "string", offset: 136}            -- 35. Description (Unknown)
  {name: "desc_lang_15", type: "string", offset: 140}            -- 36. Description (Unknown)
  {name: "desc_lang_16", type: "string", offset: 144}            -- 37. Description (Unknown)
  {name: "desc_flags", type: "uint", offset: 148}                -- 38. Description flags (16712190)
  {name: "category", type: "uint", offset: 152}                  -- 39. Category ID
  {name: "points", type: "uint", offset: 156}                    -- 40. Achievement points
  {name: "order_in_group", type: "uint", offset: 160}            -- 41. Order in group
  {name: "flags", type: "uint", offset: 164}                     -- 42. Achievement flags
  {name: "spell_icon", type: "uint", offset: 168}                -- 43. Icon ID
  -- 44-59: Reward text in different languages (16 fields)
  {name: "reward_lang_1", type: "string", offset: 172}           -- 44. Reward (English)
  {name: "reward_lang_2", type: "string", offset: 176}           -- 45. Reward (Korean)
  {name: "reward_lang_3", type: "string", offset: 180}           -- 46. Reward (French)
  {name: "reward_lang_4", type: "string", offset: 184}           -- 47. Reward (German)
  {name: "reward_lang_5", type: "string", offset: 188}           -- 48. Reward (Chinese)
  {name: "reward_lang_6", type: "string", offset: 192}           -- 49. Reward (Taiwanese)
  {name: "reward_lang_7", type: "string", offset: 196}           -- 50. Reward (Spanish Mexico)
  {name: "reward_lang_8", type: "string", offset: 200}           -- 51. Reward (Spanish)
  {name: "reward_lang_9", type: "string", offset: 204}           -- 52. Reward (Russian)
  {name: "reward_lang_10", type: "string", offset: 208}          -- 53. Reward (Portuguese)
  {name: "reward_lang_11", type: "string", offset: 212}          -- 54. Reward (Italian)
  {name: "reward_lang_12", type: "string", offset: 216}          -- 55. Reward (Unknown)
  {name: "reward_lang_13", type: "string", offset: 220}          -- 56. Reward (Unknown)
  {name: "reward_lang_14", type: "string", offset: 224}          -- 57. Reward (Unknown)
  {name: "reward_lang_15", type: "string", offset: 228}          -- 58. Reward (Unknown)
  {name: "reward_lang_16", type: "string", offset: 232}          -- 59. Reward (Unknown)
  {name: "unknown_60", type: "float", offset: 236}               -- 60. Unknown float
  {name: "criteria_count", type: "uint", offset: 240}            -- 61. Number of criteria needed
  {name: "referenced_achievement", type: "uint", offset: 244}    -- 62. Referenced achievement ID
}

-- Achievement categories (some common ones)
ACHIEVEMENT_CATEGORIES = {
  [92]: "General"
  [96]: "Quests"
  [97]: "Exploration"
  [95]: "Player vs Player"
  [168]: "Dungeons & Raids"
  [169]: "Professions"
  [201]: "Reputation"
  [155]: "World Events"
  [81]: "Feats of Strength"
}

-- Faction constants
FACTION_NAMES = {
  [-1]: "Both"
  [0]: "Alliance"
  [1]: "Horde"
}

read_achievement_dbc = (file_path) ->
  unless dbc.validate file_path
    error "Invalid or missing Achievement.dbc file: #{file_path}"

  print "=== Reading Achievement.dbc ==="

  reader = dbc.open file_path
  reader\set_field_schema ACHIEVEMENT_SCHEMA

  -- Get basic info
  info = reader\get_file_info!
  print "Records: #{info.record_count}"
  print "Fields: #{info.field_count}"
  print "String block size: #{info.string_block_size} bytes"
  print "File size: #{math.floor(info.file_size / 1024)} KB"

  print "\n=== Sample Achievements ==="

  -- Debug first record to understand string offsets
  first_record = reader\get_record 0

  -- Test if we can get numeric offset values by reading raw field data
  print "\nRaw field offsets:"
  print "Field at offset 16 (name_lang_1): #{first_record\get_field "name_lang_1"}"
  print "Field at offset 24 (name_lang_3): #{first_record\get_field "name_lang_3"}"

  -- Show first few achievements with their English names
  for i = 0, 10
    record = reader\get_record i

    id = record\get_field "id"
    title = record\get_field "name_lang_1"  -- English title
    description = record\get_field "desc_lang_1"  -- English description
    category = record\get_field "category"
    points = record\get_field "points"
    faction = record\get_field "faction"

    category_name = ACHIEVEMENT_CATEGORIES[category] or "Unknown"
    faction_name = FACTION_NAMES[faction] or "Unknown"

    print "Achievement #{id}:"
    print "  Title: #{title}"
    print "  Category: #{category_name} (#{category})"
    print "  Points: #{points}"
    print "  Faction: #{faction_name}"
    if description and #description > 0
      -- Truncate long descriptions
      desc_short = #description > 60 and description\sub(1, 60) .. "..." or description
      print "  Description: #{desc_short}"

  print "\n=== Achievement Analysis ==="

  -- Count by category
  category_counts = {}
  faction_counts = {}
  point_totals = {}

  for record in reader\records!
    category = record\get_field "category"
    faction = record\get_field "faction"
    points = record\get_field "points"

    category_counts[category] = (category_counts[category] or 0) + 1
    faction_counts[faction] = (faction_counts[faction] or 0) + 1

    faction_name = FACTION_NAMES[faction] or "Unknown"
    point_totals[faction_name] = (point_totals[faction_name] or 0) + points

  print "Achievements by Category:"
  -- Sort categories by count
  cat_sorted = {}
  for cat_id, count in pairs category_counts
    cat_sorted[#cat_sorted + 1] = {cat_id, count}

  table.sort cat_sorted, (a, b) -> a[2] > b[2]

  for i = 1, math.min(10, #cat_sorted)
    cat_id, count = cat_sorted[i][1], cat_sorted[i][2]
    cat_name = ACHIEVEMENT_CATEGORIES[cat_id] or "Unknown"
    print "  #{cat_name}: #{count}"

  print "\nAchievements by Faction:"
  for faction, count in pairs faction_counts
    faction_name = FACTION_NAMES[faction] or "Unknown"
    total_points = point_totals[faction_name] or 0
    print "  #{faction_name}: #{count} achievements (#{total_points} points total)"

  print "\n=== High-Value Achievements ==="

  -- Find achievements worth 25+ points
  high_value = reader\find_records (record) ->
    points = record\get_field "points"
    type(points) == "number" and points >= 25

  print "Achievements worth 25+ points:"
  for i = 1, math.min(10, #high_value)
    record = high_value[i]
    id = record\get_field "id"
    title = record\get_field "title_lang_1"
    points = record\get_field "points"
    category = record\get_field "category"

    category_name = ACHIEVEMENT_CATEGORIES[category] or "Unknown"
    print "  #{title} (#{points} pts) - #{category_name}"

  print "\n=== Meta Achievements ==="

  -- Find achievements that are parents to others (meta achievements)
  parent_counts = {}
  for record in reader\records!
    parent = record\get_field "parent"
    if parent and parent > 0
      parent_counts[parent] = (parent_counts[parent] or 0) + 1

  if next parent_counts
    print "Meta achievements (have sub-achievements):"
    for parent_id, child_count in pairs parent_counts
      -- Find the parent achievement
      parent_record = reader\find_record (record) ->
        record\get_field("id") == parent_id

      if parent_record
        title = parent_record\get_field "title_lang_1"
        points = parent_record\get_field "points"
        print "  #{title} (#{child_count} sub-achievements, #{points} pts)"


  reader\close!

-- Example usage
if arg and arg[1]
  achievement_file = arg[1]
  print "Reading Achievement.dbc from: #{achievement_file}"
  read_achievement_dbc achievement_file
else
  print "Usage: moon achievement_reader.moon /path/to/Achievement.dbc"
  print ""
  print "Example with typical WoW client installation:"
  print "  moon achievement_reader.moon \"C:/Program Files (x86)/World of Warcraft/Data/enUS/DBFilesClient/Achievement.dbc\""