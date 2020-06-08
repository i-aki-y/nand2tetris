require'./jack_tokenizer'


class CompilationEngine

  Types = ["int", "char", "boolean"]
  Subroutines = ["constructor", "function", "method"]
  Statements = ["let", "if", "while", "do", "return"]
  Ops = ["+", "-", "*", "/", "&", "|", "<", ">", "="]
  KeywordConst = ["true", "false", "null", "this"]

  def initialize(tokenizer)
    @tokenizer = tokenizer
    @xmls = []
    @token = nil
    @next_token = nil
  end

  def reset(input)
    @tokenizer.set_input(input)
    @xmls = []
    @token = nil
    @next_token = nil
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

  def get_token
    if @next_token.nil?
      @token = @tokenizer.get_token
    else
      @token = @next_token
    end
    p @token
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
    send(name, has_token)
    @xmls.push("</#{tag_name}>")
  end

  def add_tag(tag, value)
    @xmls.push("<#{tag}> #{value.encode({:xml => :text})} </#{tag}>")
  end

  def add_id(has_token)
    if !has_token
      get_token
    end
    if @token.type != TokenType::IDENTIFIER
      raise "Compile error, non identifier token #{@token.value} is given"
    end
    @xmls.push(@token.to_xml)
  end

  def add_symbol(sym, has_token)
    if !has_token
      get_token
    end
    if @token.value != sym
      raise "Compile error. #{@token.value} is given instead of #{sym}"
    end
    @xmls.push(@token.to_xml)
  end

  def add_keyword(keyword, has_token)
    if !has_token
      get_token
    end
    if @token.value != keyword
      raise "Compile error. #{@token.value} is given instead of #{keyword}"
    end
    @xmls.push(@token.to_xml)

  end

  def compile_class(has_token)
    if !has_token
      get_token
    end

    add_keyword("class", true)

    # className
    add_id(false)

    # {
    add_symbol("{", false)

    get_token
    while is_class_var_dec?(@token)
      call_compile("compile_class_var_dec", "classVarDec", true)
      get_token
    end

    while is_subroutine_dec?(@token)
      call_compile("compile_subroutine_dec", "SubroutineDec", true)
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

    add_tag("keyword", @token.value)

    # type
    get_token
    add_type(@token.value)

    # varName
    add_id(false)

    get_token
    while @token.value == ','
      add_symbol(",", true)

      # varName
      add_id(false)

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

    add_tag("keyword", @token.value)

    get_token
    if Types.include?(@token.value)
      add_type(@token.value)
    elsif @token.value == 'void'
      # void
      add_keyword("void", true)
    else
      raise "Unknow return type #{@token.value}"
    end

    # subroutineName
    add_id(false)

    # (
    add_symbol("(", false)

    call_compile("compile_parameter_list", "parameterList", false)

    # )
    add_symbol(")", true)

    call_compile("compile_subroutine_body", "subroutineBody", false)

  end

  def add_type(value)
    if Types.include?(value)
      # builtin type
      add_tag("keyword", value)
    else
      # className
      add_tag("identifier", value)
    end
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
      add_type(@token.value)
      # varName
      add_id(false)

      get_token
      while @token.value == ','
        add_symbol(",", true)

        # type
        get_token
        add_type(@token.value)

        # varName
        add_id(false)

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
    add_type(@token.value)

    # varName
    add_id(false)

    get_token
    while @token.value == ","
      add_symbol(",", true)

      # varName
      add_id(false)

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
        call_compile("compile_let", "letStatement", true)
        get_token
      when "if"
        call_compile("compile_if", "ifStatement", true)
        get_token
      when "while"
        call_compile("compile_while", "whileStatement", true)
        get_token
      when "do"
        call_compile("compile_do", "doStatement", true)
        get_token
      when "return"
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
    add_id(false)

    get_token
    if @token.value == '['
      # [
      add_symbol("[", true)

      call_compile("compile_expression", "expression", false)

      #]
      add_symbol("]", false)

      get_token
    end

    # =
    add_symbol("=", true)

    call_compile("compile_expression", "expression", false)

    # ;
    add_symbol(";", true)

  end

  def compile_while(has_token)
    if !has_token
      get_token
    end

    if @token.value != "while"
      raise "Compile error. #{@token.value} is given instead of 'while'"
    end

    add_keyword("while", true)

    add_symbol("(", false)

    call_compile("compile_expression", "expression", false)

    add_symbol(")", true)

    add_symbol("{", false)

    call_compile("compile_statements", "statements", false)

    add_symbol("}", true)

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
    end

    add_symbol(";", true)

  end

  def compile_if(has_token)
    if !has_token
      get_token
    end

    if @token.value != "if"
      raise "Compile error. #{@token.value} is given instead of 'if'"
    end
    add_keyword("if", true)


    add_symbol("(", false)

    call_compile("compile_expression", "expression", false)

    add_symbol(")", true)

    add_symbol("{", false)

    call_compile("compile_statements", "statements", false)

    add_symbol("}", true)

    if @next_token.value == "else"
      get_token
      add_keyword("else", true)

      add_symbol("{", false)

      call_compile("compile_statements", "statements", false)

      add_symbol("}", true)

      get_token
    end

  end

  def compile_expression(has_token)
    if !has_token
      get_token
    end

    call_compile("compile_term", "term", true)

    get_token
    while Ops.include?(@token.value)
      add_tag("symbol", @token.value)
      call_compile("compile_term", "term", false)
      get_token
    end

  end

  def compile_term(has_token)
    if !has_token
      get_token
    end

    if @token.type == TokenType::INT_CONST ||
       @token.type == TokenType::STRING_CONST ||
       KeywordConst.include?(@token.value)

      @xmls.push(@token.to_xml)

    elsif ["-", "~"].include?(@token.value)

      add_tag("symbol", @token.value)

    elsif @token.value == "("

      add_symbol("(", true)
      call_compile("compile_expression", "expression", false)

    elsif @token.type == TokenType::IDENTIFIER

      if @next_token.value == "["
        add_id(true)
        add_symbol("[", false)

        call_compile("compile_expression", "expression", false)

        add_symbol("]", false)

      elsif @next_token.value == "(" || @next_token.value == "."

        add_subroutine_call(true)

      else

        add_id(true)

      end
    end
  end

  def add_subroutine_call(has_token)
    if !has_token
      get_token
    end

    add_id(true)

    get_token
    if @token.value == "("
      add_symbol("(", true)

        call_compile("compile_expression_list", "expressionList", false)

        add_symbol(")", true)

    elsif @token.value == "."
        add_symbol(".", true)

        get_token
        add_tag("identifier", @token.value)

        add_symbol("(", false)

        call_compile("compile_expression_list", "expressionList", false)

        add_symbol(")", true)
    end

  end

  def compile_expression_list(has_token)
    if !has_token
      get_token
    end

    if @token.value != ")"
      call_compile("compile_expression", "expression", true)

      while @token.value == ","
        add_symbol(",", true)
        call_compile("compile_expression", "expression", false)

      end
    end
  end

end
