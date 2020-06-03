require 'pathname'
require './assembler'

IS_DEBUG = false

def main

  input_path_str = ARGV[0]
  parser = Parser.new({"input_path" => input_path_str})

  input_path = Pathname(input_path_str)
  output_path = input_path.sub_ext(".hack")

  while parser.has_more_command?
    parser.advance
    if parser.command_type == L_COMMAND
      parser.update_symbol_table
    end
  end

  parser.seek_init

  File.open(output_path.to_s, "w") do |of|
    while parser.has_more_command?
      parser.advance
      if parser.command_type == A_COMMAND
        parser.update_symbol_table
      end
      if [C_COMMAND, A_COMMAND].include? parser.command_type
        code = parser.get_code
        if IS_DEBUG
          p code
          of.puts code + "\t" + parser.cur_line
        else
          of.puts code
        end
      end
    end
  end

  if IS_DEBUG
    parser.ram_symbol_table.dump()
  end

end

main
