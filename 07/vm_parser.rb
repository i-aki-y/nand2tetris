
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

  PUSH_D = <<~EOS
           @SP
           A=M
           M=D
           @SP
           M=M+1
  EOS

  Seg2Reg = {
    "argument" => "ARG",
    "local" => "LCL",
    "this" => "THIS",
    "that" => "THAT",
  }

  Seg2RegIndirect = {
    "pointer" => ["THIS", "THAT"],
    "temp" => 8.times.collect { |i| "R" + (5 + i).to_s},
  }


  def initialize
    @label_table = Hash.new
  end

  def set_file_name(file_name)
    @file_name = file_name
    @func_name = ""
  end

  def make_set_ram(reg, addr)
    return <<~EOS
         @#{addr}
         D=A
         @#{reg}
         M=D
    EOS
  end

  def make_prog_end
    <<~EOS
      (__END_OF_PROGRAM__)
      @__END_OF_PROGRAM__
      0;JMP
    EOS
  end

  def make_init()
    [
      make_set_ram("SP", BaseSP),
      make_call_func("Sys.init", 0),
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
          M=M-D
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
          M=!M
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

          // else
          @SP
          A=M-1
          M=#{F}
          @#{l_ENDIF}
          0;JMP

          // if
          (#{l_IF})
          @SP
          A=M-1
          M=#{T}
          // end of if
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

    [set_D, PUSH_D].join("\n")

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
              M=D
      EOS
    elsif segment == "static"

      code = <<~EOS
              @#{index}
              D=A
              @16
              D=D+A
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

  def make_label(label)
    label = get_func_label(@func_name, label)
    "(#{label})"
  end

  def make_goto(label)
    label = get_func_label(@func_name, label)
    <<~EOS
      @#{label}
      0;JMP
    EOS
  end

  def make_if_goto(label)
    label = get_func_label(@func_name, label)
    <<~EOS
      @SP
      A=M-1
      D=M
      @SP
      M=M-1

      @#{label}
      D;JNE
    EOS
  end

  def make_push_reg(reg)
    set_D = <<~EOS
        @#{reg}
        D=M
    EOS

    [set_D, PUSH_D].join("\n")

  end

  def make_push_label(label)
    set_D = <<~EOS
        @#{label}
        D=A
    EOS

    [set_D, PUSH_D].join("\n")

  end

  def make_func(func, k)
    @func_name = func
    l_LOOP = get_func_label(func, "LOOP")
    l_END = get_func_label(func, "END")

    <<~EOS
      (#{func})
      @#{k}
      D=A
      (#{l_LOOP})
      D=D-1
      @#{l_END}
      D;JLT

      @SP
      A=M
      M=0
      @#{l_LOOP}
      0;JMP
      (#{l_END})
    EOS
  end

  def make_call_func(func, n)
    ret = get_func_label(func, "RETURN")

    code1 = [
      make_push_label(ret),
      make_push_reg("LCL"),
      make_push_reg("ARG"),
      make_push_reg("THIS"),
      make_push_reg("THAT"),
    ].join("\n")

    code2 = <<~EOS
         // ARG = SP - n - 5
         @#{n.to_i+5}
         D=A
         @SP
         D=M-D
         @ARG
         M=D

         // LCL = SP
         @SP
         D=M
         @LCL
         M=D

         // goto f
         @#{func}
         0;JMP
         (#{ret})
    EOS

    [code1, code2].join("\n")
  end

  def make_return
    <<~EOS
      // R13 = LCL
      @LCL
      D=M
      @R13
      M=D

      // R14 = *(R13-5)
      @5
      D=A
      @R13
      A=M-D
      D=M
      @R14
      M=D

      // *ARG = pop()
      // Note: Functions must have more than 1 args and a return value
      @SP
      A=M-1
      D=M
      @ARG
      A=M
      M=D

      // SP = ARG + 1
      @ARG
      D=M+1
      @SP
      M=D

      // THAT = *(R13-1)
      @R13
      A=M-1
      D=M
      @THAT
      M=D

      // THIS = *(R13-2)
      @2
      D=A
      @R13
      A=M-D
      D=M
      @THIS
      M=D

      // ARG = *(R13-3)
      @3
      D=A
      @R13
      A=M-D
      D=M
      @ARG
      M=D

      // LCL = *(R13-4)
      @4
      D=A
      @R13
      A=M-D
      D=M
      @LCL
      M=D

      // goto R14
      @R14
      A=M
      0;JMP
    EOS
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

  def get_func_label(func, label)
    func + "$" + label
  end

  def get_static_symbol(symbol)
    @file_name + "." + symbol
  end

end
