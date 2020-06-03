FREE_VAR_INDEX = 16

RESEREVED_SYMBOL = {
  "R0" => "0",
  "R1" => "1",
  "R2" => "2",
  "R3" => "3",
  "R4" => "4",
  "R5" => "5",
  "R6" => "6",
  "R7" => "7",
  "R8" => "8",
  "R9" => "9",
  "R10" => "10",
  "R11" => "11",
  "R12" => "12",
  "R13" => "13",
  "R14" => "14",
  "R15" => "15",
  "SP" => "0",
  "LCL" => "1",
  "ARG" => "2",
  "THIS" => "3",
  "THAT" => "4",
  "SCREEN" => "16384",
  "KBD" => "24576",
}

COMP_MNEMONICS = {

  #     => "acccccc"

  "0"   => "0101010",
  "1"   => "0111111",
  "-1"  => "0111010",

  "D"   => "0001100",
  "A"   => "0110000",
  "M"   => "1110000",

  "!D"  => "0001101",
  "!A"  => "0110001",
  "!M"  => "1110001",

  "-D"  => "0001111",
  "-A"  => "0110011",
  "-M"  => "1110011",

  "D+1" => "0011111",
  "A+1" => "0110111",
  "M+1" => "1110111",

  "D-1" => "0001110",
  "A-1" => "0110010",
  "M-1" => "1110010",

  "D+A" => "0000010",
  "D+M" => "1000010",

  "D-A" => "0010011",
  "D-M" => "1010011",

  "A-D" => "0000111",
  "M-D" => "1000111",

  "D&A" => "0000000",
  "D&M" => "1000000",

  "D|A" => "0010101",
  "D|M" => "1010101",
}

DEST_MNEMONICS = {
  "null" => "000",
  "M"    => "001",
  "D"    => "010",
  "MD"   => "011",
  "A"    => "100",
  "AM"   => "101",
  "AD"   => "110",
  "AMD"  => "111",
}

JUMP_MNEMONICS = {
  "null" => "000",
  "JGT"  => "001",
  "JEQ"  => "010",
  "JGE"  => "011",
  "JLT"  => "100",
  "JNE"  => "101",
  "JLE"  => "110",
  "JMP"  => "111",
}

NO_COMMAND = "No Command"
L_COMMAND = "L_COMMAND"
A_COMMAND = "A_COMMAND"
C_COMMAND = "C_COMMAND"


class Parser

  def initialize(args)
    @line_parser = LineParser.new
    @symbol_table = SymbolTable.new(RESEREVED_SYMBOL)
    @coder = Code.new
    @lines = nil
    @cur_line = nil
    @cur_rom_index = nil
    @cur_line_index = nil

    if args["lines"]
      @lines = args["lines"]
    elsif args["input_path"]
      input_path = args["input_path"]
      if input_path
        File.open(input_path, "r") do |f|
          @lines = f.readlines
        end
      end
    end

    if !@lines
      raise "Invalid argument"
    end

  end

  def has_more_command?
    index = (@cur_line_index.nil?) ? -1 : @cur_line_index
    return index < @lines.size - 1
  end

  def advance
    if !has_more_command?
      return nil
    end
    @cur_line_index = (@cur_line_index.nil?) ? 0 : @cur_line_index + 1

    @cur_line = @lines[@cur_line_index]

    res = @line_parser.parse(@cur_line)

    @cur_command_type = res["command_type"]
    @cur_comment = res["comment"]
    @cur_result = res["result"]

    if [A_COMMAND, C_COMMAND].include? @cur_command_type
      @cur_rom_index = (@cur_rom_index.nil?) ? 0 : @cur_rom_index + 1
    end
  end

  def cur_line
    @cur_line
  end

  def cur_result
    @cur_result
  end

  def command_type
    @cur_command_type
  end

  def update_symbol_table
    if self.symbol
      case @cur_command_type
      when A_COMMAND then
        @symbol_table.add_variable(self.symbol)
      when L_COMMAND then
        next_index = (@cur_rom_index.nil?) ? 0 : @cur_rom_index + 1
        @symbol_table.add_entry(self.symbol, next_index)
      end
    end
    return [@symbol_table]
  end

  def get_code
    if !([A_COMMAND, C_COMMAND].include? @cur_command_type)
      return nil
    end

    code = ""
    case @cur_command_type
    when A_COMMAND then
      val = @cur_result
      if @symbol_table.contains?(val)
        code = @coder.a_cmd(@symbol_table.get_address(val))
      else
        code = @coder.a_cmd(val)
      end
    when C_COMMAND then
      code = @coder.c_cmd(@cur_result["dest"], @cur_result["comp"], @cur_result["jump"])
    else
      code = nil
    end

    return code

  end

  def seek_init()
    @cur_line = nil
    @cur_rom_index = nil
    @cur_line_index = nil
  end

  def command_type
    return @cur_command_type
  end

  def symbol
    if [L_COMMAND, A_COMMAND].include?(@cur_command_type) && @line_parser.symbol?(@cur_result)
      return @cur_result
    else
      return nil
    end
  end

  def dest
    if C_COMMAND == @cur_command_type
      return @cur_result["dest"]
    else
      nil
    end
  end

  def comp
    if C_COMMAND == @cur_command_type
      return @cur_result["comp"]
    else
      nil
    end
  end

  def jump
    if C_COMMAND == @cur_command_type
      return @cur_result["jump"]
    else
      nil
    end
  end

  def set_label
    if @cur_command_type == L_COMMAND
      @symbol_table.add_entry(@cur_result)
    end
  end

  def symbol_table
    @symbol_table
  end

end

class LineParser

  def initialize()

  end

  def parse(line)
    if line.nil?
      raise "Invalid line"
    end

    cmd, comment = self.extract_comment(line)

    if cmd.nil? || cmd.empty?
      return {"command_type" => NO_COMMAND, "result" => nil, "comment" => comment}
    end

    if l_command_like?(cmd)
      res = parse_l_command(cmd)
      return {"command_type" => L_COMMAND, "result" => res, "comment" => comment}
    elsif a_command_like?(cmd)
      res = parse_a_command(cmd)
      return {"command_type" => A_COMMAND, "result" => res, "comment" => comment}
    elsif c_command_like?(cmd)
      res = parse_c_command(cmd)
      return {"command_type" => C_COMMAND, "result" => res, "comment" => comment}
    else
      raise "Unknow command #{cmd}"
    end

  end

  def a_command_like?(cmd)
    cmd = self.clear_spaces(cmd)
    !!(cmd =~ /^@/)
  end

  def c_command_like?(cmd)
    cmd = self.clear_spaces(cmd)
    if a_command_like?(cmd) || l_command_like?(cmd) || comment?(cmd)
      return false
    else
      return true
    end
  end

  def l_command_like?(cmd)
    cmd = self.clear_spaces(cmd)
    !!(cmd =~/^\(.+\)$/)
  end

  def comment?(cmd)
    cmd = self.clear_spaces(cmd)
    !!(cmd =~/^\/\//)
  end

  def parse_a_command(cmd)
    cmd = self.clear_spaces(cmd)
    if !a_command_like?(cmd)
      raise "Invalid A_COMMAND: #{cmd}"
    end

    a_cmd = cmd[1..-1]

    if self.symbol?(a_cmd) || self.digits?(a_cmd)
      return a_cmd
    else
      raise "Invalid A_COMMAND: #{cmd}"
    end
  end

  def parse_c_command(cmd)
    cmd = self.clear_spaces(cmd)
    if !c_command_like?(cmd)
      raise "Invalid C_COMMAND: #{cmd}"
    end

    dest, comp, jump = c_mnemonic(cmd)
    {"dest" => dest, "comp" => comp, "jump" => jump}
  end

  def validate_dest(dest)
    dest = "null" if dest.empty?
    DEST_MNEMONICS.has_key?(dest)
  end

  def validate_comp(comp)
    COMP_MNEMONICS.has_key?(comp)
  end

  def validate_jump(jump)
    jump = "null" if jump.empty?
    JUMP_MNEMONICS.has_key?(jump)
  end

  def parse_l_command(cmd)
    cmd = self.clear_spaces(cmd)
    if !l_command_like?(cmd)
      raise "Invalid L_COMMAND: #{cmd}"
    end

    token = cmd[1...-1]

    if !self.symbol?(token)
      raise "Invalid L_COMMAND: #{cmd}"
    end

    token

  end

  def extract_comment(line)
    if !line
      return [nil, nil]
    end

    m = line =~ /\/\/.*/

    if m
      command = line[0...m]
      comment = line[m..-1]
    else
      command = line
      comment = nil
    end

    command.gsub!(/\s/, "")

    [command, comment]
  end


  def c_mnemonic(cmd)

    dest, comp, jump = "", "", ""

    if cmd =~ /=/
      dest, cmd = cmd.split("=", 2)

      if dest.empty?
        raise "Invalid C_COMMAND: #{cmd}"
      end

    end

    if cmd =~ /;/
      comp, jump = cmd.split(";", 2)

      if jump.empty?
        raise "Invalid C_COMMAND: #{cmd}"
      end

    else

      comp = cmd

    end

    if comp.empty?
      raise "Invalid C_COMMAND: #{cmd}"
    end

    if validate_dest(dest) && validate_comp(comp) && validate_jump(jump)
      return [dest, comp, jump]
    else
      raise "Invalid C_COMMAND: #{cmd}"
    end

  end


  def value?(s)
    symbol?(s) || digits?(s)
  end

  def symbol?(s)
    !(s =~ /[^0-9A-Za-z:._$]/) && !(s =~ /^\d/)
  end

  def digits?(s)
    !(s =~ /[^\d]/)
  end

  def clear_spaces(s)
    s.gsub(/\s/, "")
  end

end


class SymbolTable

  def initialize(init=nil)
    @table = Hash.new
    if init
      init.each_pair {|k, v| self.add_entry(k, v)}
    end
    @next_free_index = FREE_VAR_INDEX
  end

  def add_entry(symbol, address)
    @table[symbol] = address.to_s
  end

  def contains?(symbol)
    @table.has_key?(symbol)
  end

  def get_address(symbol)
    @table[symbol]
  end

  def add_variable(symbol)
    if @table.has_key?(symbol)
      return @table[symbol]
    else
      self.add_entry(symbol, @next_free_index)
      @next_free_index += 1
    end
  end

  def dump
    @table.each_pair{ |k, v| print(k, "\t", v, "\n") }
  end

end



class Code

  def dest(m)
    m = "null" if m.empty?
    DEST_MNEMONICS[m]
  end

  def comp(m)
    COMP_MNEMONICS[m]
  end

  def jump(m)
    m = "null" if m.empty?
    JUMP_MNEMONICS[m]
  end

  def a_cmd(digits)
    sprintf("0%015b", digits.to_i)
  end

  def c_cmd(dest, comp, jump)
    ["111", self.comp(comp), self.dest(dest), self.jump(jump)].join()
  end

end
