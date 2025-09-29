-- TLK-DBC: World of Warcraft TLK DBC file reader/writer
-- Clean modular architecture with proper separation of concerns

-- Core components
DbcReader = require "src.core.dbc_reader"
DbcWriter = require "src.core.dbc_writer"
DbcHeader = require "src.core.dbc_header"

-- I/O components
BinaryReader = require "src.io.binary_reader"
BinaryWriter = require "src.io.binary_writer"

-- Pattern implementations
{DbcRecord, DbcRecordBuilder} = require "src.patterns.dbc_record"
StringManager = require "src.patterns.string_manager"

-- Main module interface
{
  -- Primary functions
  open: (file_path, options = {}) -> DbcReader.open file_path, options
  validate: (file_path) -> DbcReader.validate_file file_path

  -- Writer functions
  open_for_edit: (file_path, options = {}) -> DbcWriter.open file_path, options
  writer: (reader_or_path, options = {}) -> DbcWriter reader_or_path, options

  -- Direct access to classes for advanced usage
  :DbcReader, :DbcWriter, :DbcHeader, :DbcRecord, :DbcRecordBuilder
  :BinaryReader, :BinaryWriter, :StringManager

  -- Version info
  VERSION: "1.0.0"
}