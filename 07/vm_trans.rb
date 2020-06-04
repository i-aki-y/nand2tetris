require 'pathname'

C_ARITHMETIC = 1
C_PUSH = 2
C_POP = 3
C_LABEL = 4
C_GOTO = 5
C_IF = 6
C_FUNCTION = 7
C_RETURN = 8
C_CALL = 9

class Parser

  def initialize(args)
    @line_parser = LineParser.new
    @lines = nil
    @cur_line = nil
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
      raise "No input"
    end
  end

  def get_next_index
    (@cur_line_index.nil?) ? 0 : @cur_line_index + 1
  end

  def has_more_command?
    return get_next_index < @lines.size
  end

  def advance
    if !has_more_command?
      return nil
    end
    @cur_line_index = get_next_index
    @cur_line = @lines[@cur_line_index]

    res = @line_parser.parse(@cur_line)
    @cur_command_type  = res["c_type"]
    @cur_arg1 = res["arg1"]
    @cur_arg2 = res["arg2"]
    @cur_comment = res["comment"]

  end

  def command_type
    @cur_command_type
  end

  def arg1
    @cur_arg1
  end

  def arg2
    @cur_arg2
  end

end


class LineParser

  def initialize()

  end

  def parse(line)
    if line.nil?
      raise "Invalid line"
    end

    cmds, comment = self.extract_comment(line)
    cmds = "" if cmds.nil?
    cmd, *args = cmds.split(/\s+/)
    cmd = "" if cmd.nil?

    if args.size > 2
      raise "Too many argument #{args}"
    end

    arg1, arg2 = args
    res = {"comment" => comment}

    case cmd
    when ""
      res["c_type"], res["arg1"], res["arg2"] = nil, nil, nil
    when "add"
      res["c_type"], res["arg1"], res["arg2"] = C_ARITHMETIC, cmd, nil
    when "sub"
      res["c_type"], res["arg1"], res["arg2"] = C_ARITHMETIC, cmd, nil
    when "neg"
      res["c_type"], res["arg1"], res["arg2"] = C_ARITHMETIC, cmd, nil
    when "eq"
      res["c_type"], res["arg1"], res["arg2"] = C_ARITHMETIC, cmd, nil
    when "gt"
      res["c_type"], res["arg1"], res["arg2"] = C_ARITHMETIC, cmd, nil
    when "lt"
      res["c_type"], res["arg1"], res["arg2"] = C_ARITHMETIC, cmd, nil
    when "and"
      res["c_type"], res["arg1"], res["arg2"] = C_ARITHMETIC, cmd, nil
    when "or"
      res["c_type"], res["arg1"], res["arg2"] = C_ARITHMETIC, cmd, nil
    when "not"
      res["c_type"], res["arg1"], res["arg2"] = C_ARITHMETIC, cmd, nil
    when "push"
      res["c_type"], res["arg1"], res["arg2"] = C_PUSH, arg1, arg2
    when "pop"
      res["c_type"], res["arg1"], res["arg2"] = C_POP, arg1, arg2
    when "label"
      res["c_type"], res["arg1"], res["arg2"] = C_LABEL, arg1, arg2
    when "goto"
      res["c_type"], res["arg1"], res["arg2"] = C_GOTO, arg1, arg2
    when "if-goto"
      res["c_type"], res["arg1"], res["arg2"] = C_IF, arg1, arg2
    when "function"
      res["c_type"], res["arg1"], res["arg2"] = C_FUNCTION, arg1, arg2
    when "call"
      res["c_type"], res["arg1"], res["arg2"] = C_CALL, arg1, arg2
    when "return"
      res["c_type"], res["arg1"], res["arg2"] = C_RETURN, arg1, arg2
    else
      raise "Unknown command #{cmd}"
    end

    return res

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

    command.strip!

    [command, comment]
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


class CodeWriter

  BaseSP = 256
  BaseLCL = 400
  BaseARG = 500
  BaseTHIS = 3000
  BaseTHAT = 4000
  T = -1
  F = 0

  Seg2Reg = {
    "argument" => "ARG",
    "local" => "LCL",
    "this" => "THIS",
    "that" => "THAT",
  }

  Seg2RegIndirect = {
    "pointer" => ["THIS", "THAT"],
    "temp" => 8.times.collect { |i| "R" + (13 + i).to_s}
  }

  def initialize
    @label_table = Hash.new
  end

  def set_file_name(file_name)
    @file_name = file_name
  end

  def make_set_ram(reg, addr)
    return <<~EOS
         @#{addr}
         D=A
         @#{reg}
         M=D
    EOS
  end

  def make_init()
    [
      make_set_ram("SP", BaseSP),
      make_set_ram("LCL", BaseLCL),
      make_set_ram("ARG", BaseARG),
      make_set_ram("THIS", BaseTHIS),
      make_set_ram("THAT", BaseTHAT),
    ].join("\n")
  end

  def make_arithmetic(command)

    case command
    when "add"
      code = <<~EOS
          @SP
          A=M-1
          D=M
          A=A-1
          M=D+M
          @SP
          M=M-1
      EOS
    when "sub"
      code = <<~EOS
          @SP
          A=M-1
          D=M
          A=A-1
          M=D-M
          @SP
          M=M-1
      EOS
    when "neg"
      code = <<~EOS
          @SP
          A=M-1
          D=M
          M=-D
      EOS
    when "eq"
      code = make_cond("JEQ")
    when "gt"
      code = make_cond("JGT")
    when "lt"
      code = make_cond("JLT")
    when "and"
      code = make_and_or("&")
    when "or"
      code = make_and_or("|")
    when "not"
      code = <<~EOS
          @SP
          A=M-1
          M=-M
      EOS

    else
      raise"Unknow command"
    end
    return code
  end

  def make_and_or(op)
      code = <<~EOS
          @SP
          A=M-1
          D=M
          A=A-1
          M=D#{op}M
          @SP
          M=M-1
      EOS
      return code
  end

  def make_cond(jmp)
      l_IF = get_new_label("IF")
      l_ELSE = get_new_label("ELSE")
      l_ENDIF = get_new_label("ENDIF")
      code = <<~EOS
          @SP
          A=M-1
          D=M
          A=A-1
          D=M-D
          @SP
          M=M-1
          @#{l_IF}
          D;#{jmp}
          (#{l_IF})
          @SP
          A=M-1
          M=#{T}
          @#{l_ENDIF}
          0;JMP
          (#{l_ELSE})
          @SP
          A=M-1
          M=#{F}
          (#{l_ENDIF})
      EOS
      return code
  end

  def make_push_pop(command, segment, index)

    case command
    when C_PUSH
      code = make_push(command, segment, index)
    when C_POP
      code = make_pop(command, segment, index)
    else
      raise "Unknow command #{command}"
    end

    return code

  end

  def make_push(command, segment, index)
          push_D = <<~EOS
                @SP
                A=M
                M=D
                @SP
                M=M+1

        EOS
      if Seg2Reg.has_key?(segment)
        reg = Seg2Reg[segment]
        set_D = <<~EOS
                @#{index}
                D=A
                @#{reg}
                A=D+M
                D=M

        EOS
      elsif Seg2RegIndirect.has_key?(segment)
        reg = Seg2RegIndirect[segment][index.to_i]
        set_D = <<~EOS
                @#{reg}
                A=M
                D=M
        EOS
      elsif segment == "constant"
        set_D = <<~EOS
                @#{index}
                D=A
        EOS
      elsif segment == "static"
        set_D = <<~EOS
                @#{index}
                D=A
                @16
                A=D+A
                D=M
        EOS
      else
        raise "Unknow segment #{segment}"
      end

      [set_D, push_D].join("\n")

  end


  def make_pop(command, segment, index)

    if Seg2Reg.has_key?(segment)
      reg = Seg2Reg[segment]

      code = <<~EOS
              @#{index}
              D=A
              @#{reg}
              D=D+M
              @R13
              M=D

              @SP
              A=M-1
              D=M
              @SP
              M=M-1
              @R13
              A=M
              M=D

      EOS

    elsif Seg2RegIndirect.has_key?(segment)
      reg = Seg2RegIndirect[segment][index.to_i]

      code = <<~EOS
              @SP
              A=M-1
              D=M
              @SP
              M=M-1
              @#{reg}
              D=M
              @R13
              A=M
              M=D
      EOS
    elsif segment == "static"

      code = <<~EOS
              @#{index}
              D=A
              @16
              D=D+M
              @R13
              M=D

              @SP
              A=M-1
              D=M
              @SP
              M=M-1
              @R13
              A=M
              M=D

      EOS
    end

    code

  end

  def get_new_label(prefix)
    if @label_table.has_key?(prefix)
      @label_table[prefix] += 1
      return prefix + @label_table[prefix].to_s
    else
      @label_table[prefix] = 0
      return prefix + 0.to_s
    end
  end

end


def main
  input_path_str = ARGV[0]
  parser = Parser.new({"input_path" => input_path_str})
  writer = CodeWriter.new

  input_path = Pathname(input_path_str)
  output_path = input_path.sub_ext(".asm")

  File.open(output_path.to_s, "w") do |of|
    of.puts writer.make_init
    while parser.has_more_command?
      parser.advance
      code = ""
      case parser.command_type
      when C_ARITHMETIC
        code = writer.make_arithmetic(parser.arg1)
      when C_PUSH
        code = writer.make_push(parser.command_type, parser.arg1, parser.arg2)
      when C_POP
        code = writer.make_pop(parser.command_type, parser.arg1, parser.arg2)
      end
      if !code.empty?
        of.puts code
      end
    end
  end
end


if __FILE__ == $0
    main
end
