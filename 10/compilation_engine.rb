require'./jack_tokenizer'
require'./symbol_table'
require './vmwriter'

class CompilationEngine

  Types = ["int", "char", "boolean"]
  Subroutines = ["constructor", "function", "method"]
  Statements = ["let", "if", "while", "do", "return"]
  Ops = ["+", "-", "*", "/", "&", "|", "<", ">", "="]
  KeywordConst = ["true", "false", "null", "this"]

  def initialize(tokenizer)
    @tokenizer = tokenizer
    clear_all
  end

  def reset(input)
    @tokenizer.set_input(input)
    clear_all
  end

  def clear_all
    @xmls = []
    @symbol_table = SymbolTable.new
    @token = nil
    @next_token = nil
    @class_name = ""
    @vmwriter = VMWriter.new
    @label_table = {}
  end



  def compile
    get_token
    while @token

      if @token.type == TokenType::KEYWORD

        case Keywords[@token.value]
        when "CLASS"
          call_compile("compile_class", "class", true)
        when "STATIC", "FIELD"
          call_compile("compile_class_var_dec", "classVarDec", true)
        when "CONSTRUCTOR", "FUNCTION", "METHOD"
          call_compile("compile_subroutine_dec", "subroutineDec", true)
        when "VAR"
          call_compile("compile_var_dec", "varDec", true)
        end
      else
        raise "Compile error. Unknow top level token #{token.value} is given"
      end

      get_token
    end
  end

  def dump_xml
    @xmls.join("\n")
  end

  def dump_vm
    @vmwriter.dump_vm()
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


  def get_token
    if @next_token.nil?
      @token = @tokenizer.get_token
    else
      @token = @next_token
    end
    # p @token
    @next_token = @tokenizer.get_token
  end

  def get_valid_token(expect_type)
    get_token
    if @token.type != expect_type
      raise "Comile error:\n #{@token.value} is given after \n #{@xmls}"
    end
  end

  def call_compile(name, tag_name, has_token)
    @xmls.push("<#{tag_name}>")
    ret = send(name, has_token)
    @xmls.push("</#{tag_name}>")
    ret
  end

  def add_tag(tag, value)
    @xmls.push("<#{tag}> #{value.encode({:xml => :text})} </#{tag}>")
    value
  end

  def add_id(has_token)
    if !has_token
      get_token
    end
    if @token.type != TokenType::IDENTIFIER
      raise "Compile error, non identifier token #{@token.value} is given"
    end

    @xmls.push(@token.to_xml)
    @token.value
  end

  def add_symbol(sym, has_token)
    if !has_token
      get_token
    end
    if @token.value != sym
      raise "Compile error. #{@token.value} is given instead of #{sym}"
    end
    @xmls.push(@token.to_xml)
    @token.value
  end

  def add_keyword(keyword, has_token)
    if !has_token
      get_token
    end
    if @token.value != keyword
      raise "Compile error. #{@token.value} is given instead of #{keyword}"
    end
    @xmls.push(@token.to_xml)
    @token.value
  end

  def add_type()
    if Types.include?(@token.value)
      # builtin type
      add_tag("keyword", @token.value)
    else
      # className
      add_id(true)
    end
  end

  def pop_ignore()
    # In order to discard stack, use the last temp segment.
    @vmwriter.write_pop("temp", 7)
  end

  def define(name, type, kind)
    @symbol_table.define(name, type, kind)
  end

  def compile_class(has_token)
    if !has_token
      get_token
    end

    add_keyword("class", true)

    # className
    @class_name = add_id(false)

    # {
    add_symbol("{", false)

    get_token
    while is_class_var_dec?(@token)
      call_compile("compile_class_var_dec", "classVarDec", true)
      get_token
    end

    while is_subroutine_dec?(@token)
      call_compile("compile_subroutine_dec", "subroutineDec", true)
      get_token
    end

    # }
    add_symbol("}", true)

  end

  def is_class_var_dec?(token)
    (!token.nil?) && ["static", "field"].include?(token.value)
  end

  def is_subroutine_dec?(token)
    (!token.nil?) && ["constructor", "function", "method"].include?(token.value)
  end

  def compile_class_var_dec(has_token)
    if !has_token
      get_token
    end

    kind = add_tag("keyword", @token.value).to_sym

    # type
    get_token
    type = add_type()

    # varName
    define(add_id(false), type, kind)

    get_token
    while @token.value == ','
      add_symbol(",", true)

      # varName
      define(add_id(false), type, kind)

      # next token
      get_token
    end

    if @token.value != ';'
      raise "Comile error:\n #{@token.value} is given after \n #{@xmls}"
    else
      add_symbol(";", true)
    end
  end

  def compile_subroutine_dec(has_token)
    if !has_token
      get_token
    end
    @symbol_table.start_subroutine
    subroutine_type = add_tag("keyword", @token.value)

    get_token
    if Types.include?(@token.value) || @token.type == TokenType::IDENTIFIER
      add_type()
    elsif @token.value == 'void'
      # void
      add_keyword("void", true)
    else
      raise "Unknow return type #{@token.value}"
    end

    # subroutineName
    subroutine_name = add_id(false)

    # (
    add_symbol("(", false)

    if "method" == subroutine_type
      # Register "this" as the first argument
      # m.func(a,b,c) -> M.func(this, a, b, c)
      define("this", @class_name, :arg)
    end

    call_compile("compile_parameter_list", "parameterList", false)

    # )
    add_symbol(")", true)


    @vmwriter.start_subroutine
    if "method" == subroutine_type
      # Make the "this" argument point the "this" segment
      @vmwriter.write_push("argument", 0)
      @vmwriter.write_pop("pointer", 0)

    elsif subroutine_type == "constructor"
      # Allocate memory for the instance
      size = @symbol_table.var_count(:field)
      @vmwriter.write_push("constant", size)
      @vmwriter.write_call("Memory.alloc", 1)
      @vmwriter.write_pop("pointer", 0)
    end

    # delegate subroutine_body compilation
    call_compile("compile_subroutine_body", "subroutineBody", false)
    @vmwriter.end_subroutine

    # This should be after the evaluation of the subroutine body
    nlocal = @symbol_table.var_count(:var)

    @vmwriter.write_function("#{@class_name}.#{subroutine_name}", nlocal)

    # This method makes subrougine body be written after the function declaration
    @vmwriter.concat_sub_cmds

  end

  def compile_subroutine_body(has_token)
    if !has_token
      get_token
    end

    # {
    add_symbol("{", true)

    get_token
    while @token.value == 'var'
      call_compile("compile_var_dec", "varDec", true)
      get_token
    end

    call_compile("compile_statements", "statements", true)

    # }
    add_symbol("}", true)
  end

  def compile_parameter_list(has_token)
    if !has_token
      get_token
    end

    while @token.value != ")"

      # type
      type = add_type()
      # varName
      define(add_id(false), type, :arg)

      get_token
      while @token.value == ','
        add_symbol(",", true)

        # type
        get_token
        type = add_type()

        # varName
        define(add_id(false), type, :arg)
        get_token
      end
    end
  end

  def compile_var_dec(has_token)
    if !has_token
      get_token
    end

    if ! @token.value == "var"
      raise "Compile error. #{@token.value} is given instead of var"
    end

    add_keyword("var", true)

    # type
    get_token
    type = add_type()

    # varName
    define(add_id(false), type, :var)

    get_token
    while @token.value == ","
      add_symbol(",", true)

      # varName
      define(add_id(false), type, :var)
      get_token
    end

    # ;
    add_symbol(";", true)

  end

  def compile_statements(has_token)
    if !has_token
      get_token
    end

    while Statements.include?(@token.value)

      case @token.value
      when "let"
        # puts "stm: let"
        call_compile("compile_let", "letStatement", true)
        get_token
      when "if"
        # puts "stm: if"
        call_compile("compile_if", "ifStatement", true)
        get_token
      when "while"
        # puts "stm: while"
        call_compile("compile_while", "whileStatement", true)
        get_token
      when "do"
        # puts "stm: do"
        call_compile("compile_do", "doStatement", true)
        get_token
      when "return"
        # puts "stm: return"
        call_compile("compile_return", "returnStatement", true)
        get_token
      end

    end

  end

  def compile_do(has_token)
    if !has_token
      get_token
    end

    if @token.value != "do"
      raise "Compile error. #{@token.value} is given instead of 'do'"
    end
    add_keyword("do", true)

    add_subroutine_call(false)

    add_symbol(";", false)

    pop_ignore()

  end

  def compile_let(has_token)
    if !has_token
      get_token
    end

    if @token.value != "let"
      raise "Compile error. #{@token.value} is given instead of 'let'"
    end
    add_keyword("let", true)

    # varName
    name = add_id(false)
    item = @symbol_table.get_item(name)

    get_token
    if @token.value == '['
      @vmwriter.start_buf
      # [
      add_symbol("[", true)

      call_compile("compile_expression", "expression", false)

      #]
      add_symbol("]", true)

      @vmwriter.end_buf

      get_token

      # =
      add_symbol("=", true)

      call_compile("compile_expression", "expression", false)

      # ;
      add_symbol(";", true)

      @vmwriter.concat_buf

      case item.kind
      when :var
        @vmwriter.write_push("local", item.index)
      when :static
        @vmwriter.write_push("static", item.index)
      when :field
        @vmwriter.write_push("this", item.index)
      when :arg
        @vmwriter.write_push("argument", item.index)
      end

      @vmwriter.write_arithmetic("add")
      @vmwriter.write_pop("pointer", 1)
      @vmwriter.write_pop("that", 0)

    else
      # =
      add_symbol("=", true)

      call_compile("compile_expression", "expression", false)

      # ;
      add_symbol(";", true)

      case item.kind
      when :var
        @vmwriter.write_pop("local", item.index)
      when :static
        @vmwriter.write_pop("static", item.index)
      when :field
        @vmwriter.write_pop("this", item.index)
      when :arg
        @vmwriter.write_pop("argument", item.index)
      end

    end

  end

  def compile_while(has_token)
    if !has_token
      get_token
    end

    if @token.value != "while"
      raise "Compile error. #{@token.value} is given instead of 'while'"
    end

    label_in = get_new_label("WHILE_IN")
    label_out = get_new_label("WHILE_OUT")

    @vmwriter.write_label(label_in)
    add_keyword("while", true)

    add_symbol("(", false)

    call_compile("compile_expression", "expression", false)

    add_symbol(")", true)

    @vmwriter.write_arithmetic("not")
    @vmwriter.write_if(label_out)

    add_symbol("{", false)

    call_compile("compile_statements", "statements", false)

    add_symbol("}", true)

    @vmwriter.write_goto(label_in)
    @vmwriter.write_label(label_out)

  end


  def compile_return(has_token)
    if !has_token
      get_token
    end

    if @token.value != "return"
      raise "Compile error. #{@token.value} is given instead of 'return'"
    end
    add_keyword("return", true)

    get_token
    if @token.value != ";"
      call_compile("compile_expression", "expression", true)
    else
      # If the function is void then it returns 0.
      @vmwriter.write_push("constant", 0)
    end

    add_symbol(";", true)

    @vmwriter.write_return

  end

  def compile_if(has_token)
    if !has_token
      get_token
    end

    if @token.value != "if"
      raise "Compile error. #{@token.value} is given instead of 'if'"
    end
    add_keyword("if", true)

    label_else = get_new_label("END_IF")
    label_end_if = get_new_label("ELSE")

    add_symbol("(", false)

    call_compile("compile_expression", "expression", false)

    add_symbol(")", true)

    @vmwriter.write_arithmetic("not")
    @vmwriter.write_if(label_else)

    add_symbol("{", false)

    call_compile("compile_statements", "statements", false)

    add_symbol("}", true)

    @vmwriter.write_goto(label_end_if)
    @vmwriter.write_label(label_else)
    if @next_token.value == "else"
      get_token
      add_keyword("else", true)

      add_symbol("{", false)

      call_compile("compile_statements", "statements", false)

      add_symbol("}", true)
    end
    @vmwriter.write_label(label_end_if)

  end

  def compile_expression(has_token)
    if !has_token
      get_token
    end

    call_compile("compile_term", "term", true)

    get_token
    while Ops.include?(@token.value)
      op = add_tag("symbol", @token.value)
      call_compile("compile_term", "term", false)

      write_ops_command(op)

      get_token
    end

  end

  def write_ops_command(op)
    case op
    when "+"
      @vmwriter.write_arithmetic("add")
    when "-"
      @vmwriter.write_arithmetic("sub")
    when "*"
      @vmwriter.write_call("Math.multiply", 2)
    when "/"
      @vmwriter.write_call("Math.divide", 2)
    when "&"
      @vmwriter.write_arithmetic("and")
    when "|"
      @vmwriter.write_arithmetic("or")
    when ">"
      @vmwriter.write_arithmetic("gt")
    when "<"
      @vmwriter.write_arithmetic("lt")
    when "="
      @vmwriter.write_arithmetic("eq")
    end
  end

  def compile_term(has_token)
    if !has_token
      get_token
    end

    if @token.type == TokenType::INT_CONST

      @xmls.push(@token.to_xml)
      @vmwriter.write_push("constant", @token.value)

    elsif @token.type == TokenType::STRING_CONST

      @xmls.push(@token.to_xml)

      str = @token.value
      len = str.size
      @vmwriter.write_push("constant", len)
      @vmwriter.write_call("String.new", 1)
      str.chars.each do |ch|
        @vmwriter.write_push("constant", ch.ord)
        @vmwriter.write_call("String.appendChar", 2)
      end

    elsif KeywordConst.include?(@token.value)

      @xmls.push(@token.to_xml)
      case @token.value
      when "true"
        @vmwriter.write_push("constant", 1)
        @vmwriter.write_arithmetic("neg")
      when "false", "null"
        @vmwriter.write_push("constant", 0)
      when "this"
        @vmwriter.write_push("pointer", 0)
      end

    elsif "-" == @token.value

      add_tag("symbol", @token.value)
      call_compile("compile_term", "term", false)

      @vmwriter.write_arithmetic("neg")

    elsif "~" == @token.value
      add_tag("symbol", @token.value)
      call_compile("compile_term", "term", false)

      @vmwriter.write_arithmetic("not")

    elsif @token.value == "("

      add_symbol("(", true)
      call_compile("compile_expression", "expression", false)
      add_symbol(")", true)

    elsif @token.type == TokenType::IDENTIFIER

      if @next_token.value == "["

        var_name = add_id(true)
        idx = @symbol_table.index_of(var_name)
        kind = @symbol_table.kind_of(var_name)
        case kind
        when :static
          seg = "static"
        when :field
          seg = "this"
        when :var
          seg = "local"
        when :arg
          seg = "argument"
        end
        @vmwriter.write_push(seg, idx)

        add_symbol("[", false)

        call_compile("compile_expression", "expression", false)

        add_symbol("]", true)

        @vmwriter.write_arithmetic("add")
        @vmwriter.write_pop("pointer", 1)
        @vmwriter.write_push("that", 0)

      elsif @next_token.value == "(" || @next_token.value == "."

        add_subroutine_call(true)

      else

        var_name = add_id(true)
        idx = @symbol_table.index_of(var_name)
        kind = @symbol_table.kind_of(var_name)

        case kind
        when :static
          seg = "static"
        when :field
          seg = "this"
        when :var
          seg = "local"
        when :arg
          seg = "argument"
        end
        @vmwriter.write_push(seg, idx)
      end
    end
  end

  def add_subroutine_call(has_token)
    if !has_token
      get_token
    end

    name = add_id(true)
    get_token

    if @token.value == "("
      add_self_method_call(name)
    elsif @token.value == "."
      # ClassName.yyy() or obj.yyy()
      add_symbol(".", true)

      method_name = add_id(false)

      item = @symbol_table.get_item(name)

      if item != nil
        add_instance_method_call(method_name, item)
      else
        add_class_method_call(name, method_name)
      end

    end

  end

  def add_self_method_call(name)

    add_symbol("(", true)

    # Set "this" pointer as the first argument
    @vmwriter.write_push("pointer", 0)

    nargs = call_compile("compile_expression_list", "expressionList", false)

    # Increment nargs for extra "this" argument
    nargs += 1

    add_symbol(")", true)
    full_method_name = @class_name + "." + name
    @vmwriter.write_call(full_method_name, nargs)

  end

  def add_instance_method_call(method_name, item)

    # obj.yyy()

    # Set instance's address as the first argument
    if item.kind == :static
      @vmwriter.write_push("static", item.index)
    elsif item.kind == :field
      @vmwriter.write_push("this", item.index)
    elsif item.kind == :var
      @vmwriter.write_push("local", item.index)
    elsif item.kind == :arg
      @vmwriter.write_push("argument", item.index)
    end

    # item.type == ClassName
    full_method_name = item.type + "." + method_name

    add_symbol("(", false)

    nargs = call_compile("compile_expression_list", "expressionList", false)

    # Increment nargs for extra "this" argument
    nargs += 1

    add_symbol(")", true)

    @vmwriter.write_call(full_method_name, nargs)
  end

  def add_class_method_call(class_name, method_name)
    # ClassName.yyy() // other class's function call
    full_method_name = class_name + "." + method_name

    add_symbol("(", false)

    nargs = call_compile("compile_expression_list", "expressionList", false)

    add_symbol(")", true)

    @vmwriter.write_call(full_method_name, nargs)

  end

  def compile_expression_list(has_token)
    if !has_token
      get_token
    end

    arg_count = 0

    if @token.value != ")"
      call_compile("compile_expression", "expression", true)
      arg_count += 1
      while @token.value == ","
        add_symbol(",", true)
        call_compile("compile_expression", "expression", false)
        arg_count += 1
      end
    end
    arg_count
  end

end
