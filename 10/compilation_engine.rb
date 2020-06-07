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
    @token
  end

  def compile
    get_token
    while @token

      case token.type
      when TokenType::KEYWORD
        case Keywords[token.value]
        when "CLASS"
          compile_class
        end

      when TokenType::KEYWORD
      end

      get_token
    end

  end

  def get_token
    if @next_token.nil?
      @token = @tokenizer.get_token
    else
      @token = @next_token
    end
    @next_token = @tokenizer.get_token
  end

  def get_valid_token(expect_type)
    @token = @tokenizer.get_token
    if token.type != expect_type
      raise "Comile error:\n #{token} is given after \n #{xml}"
    end
  end

  def call_compile(name, tag_name, has_token)
    @xmls.push("<#{tag_name}>")
    send(name, has_token)
    @xml.push("<#{tag_name}>")
  end

  def add_tag(tag, value)
    @xmls.push("<#{tag}> #{value} </#{tag}>")
  end

  def compile_class(has_token)
    if !has_token
      get_token
    end

    add_tag("keyword", "class")

    # className
    get_valid_token(TokenType::IDENTIFIER)
    @xmls.push(@token.to_xml)
    # {
    get_valid_token(TokenType::SYMBOL)
    @xmls.push(@token.to_xml)

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
    get_valid_token(TokenType::SYMBOL)
    @xml.push(@token.to_xml)

  end

  def is_class_var_dec?(token)
    (!token.nil?) && ["static", "field"].include?(token.value)
  end

  def is_subroutine_dec?(token)
    (!token.nil?) && ["constructor", "function", "method"].include?(token.value)
  end

  def compile_class_var(has_token)
    if !has_token
      get_token
    end

    add_tag("keyword", @token.value)

    # type
    get_token
    add_type(@token.value)

    # varName
    get_valid_token(TokenType::IDENTIFIER)
    add_tag("identifier", @token.value)

    get_tokne
    while @token.value == ','
      add_symbol(",")

      # varName
      get_token
      get_valid_token(TokenType::IDENTIFIER)
      add_tag("identifier", @token.value)

      # next token
      get_token
    end

    if @token.value != ';'
      raise "Comile error:\n #{token} is given after \n #{xml}"
    else
      add_symbol(";")
    end
  end

  def compile_subroutine_dec(has_token)
    if !has_token
      get_token
    end

    add_tag("keyward", @token.value)

    get_value
    if Types.include?(@token.value)
      add_type(@token.value)
    elsif @token.value == 'void'
      # void
      add_tag("keyward", @token.value)
    else
      raise "Unknow return type #{@token.value}"
    end

    # subroutineName
    get_token
    add_tag("identifier", @token.value)

    # (
    get_token
    add_symbol("(")

    get_token
    if @token.value != ")"
      call_compile("compile_parameter_list", "parameterList", true)
    end

    # )
    get_token
    add_symbol(")")

    call_compile("compile_subroutine_body", "subroutineBody", false)

  end

  def add_type(value)
    if Types.include?(value)
      # builtin type
      add_tag("keyward", value)
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
    get_valid_token(TokenType::SYMBOL)
    add_symbol("{")

    get_token
    while @token.value == 'var'
      call_compile("compile_var_dec", "varDec", true)
      get_token
    end

    while Statements.include?(@token.value)
      case @token.value
      when "let"
        call_compile("compile_let", "letStatement", true)
      when "if"
        call_compile("compile_if", "ifStatement", true)
      when "while"
        call_compile("compile_while", "whileStatement", true)
      when "do"
        call_compile("compile_do", "doStatement", true)
      when "return"
        call_compile("compile_return", "returnStatement", true)
      end
      get_token
    end

    # }
    add_symbol("}")

  end

  def compile_parameter_list(has_token)
    if !has_token
      get_token
    end

    add_type(@token.value)
    get_token

    while @token.value == ','
      add_symbol(",")

      # type
      get_token
      add_type(@token.value)

      # varName
      get_token
      add_tag("identifier", @token.value)
    end

  end

  def compile_var_dec(has_token)
    if !has_token
      get_token
    end

    if ! @token.value == "var"
      raise "Compile error. #{@token.value} is given instead of var"
    end

    add_tag("keyword", @token.value)

    # type
    get_token
    add_type(@token.value)

    # varName
    get_token
    add_tag("identifier", @token.value)

    get_token
    while @token.value == ","
      add_symbol(",")

      # varName
      get_token
      add_tag("identifier", @token.value)

      get_token
    end

    # ;
    add_symbol(";")

  end

  def compile_statements(has_token)

  end


  def compile_statement(has_token)
    if !has_token
      get_token
    end

  end

  def compile_do(has_token)
    if !has_token
      get_token
    end

    if @token.value != "do"
      raise "Compile error. #{@token.value} is given instead of 'do'"
    end
    add_tag("keyword", @token.value)

    call_compile("compile_subroutine_call", "subroutineCall", false)

    get_token
    add_symbol(";")

  end

  def compile_let(has_token)
    if !has_token
      get_token
    end

    if @token.value != "let"
      raise "Compile error. #{@token.value} is given instead of 'let'"
    end
    add_tag("keyword", @token.value)

    # varName
    get_token
    add_tag("identifier", @token.value)

    get_token
    if @token.value == '['
      # [
      add_symbol("[")

      call_compile("compile_expression", "expression", false)

      #]
      get_token
      add_symbol("]")

      get_token
    end

    # =
    add_symbol("=")

    call_compile("compile_expression", "expression", false)

    # ;
    get_token
    add_symbol(";")

  end

  def compile_wile(has_token)
    if !has_token
      get_token
    end

    if @token.value != "while"
      raise "Compile error. #{@token.value} is given instead of 'while'"
    end
    add_tag("keyword", @token.value)

    get_token
    add_symbol("(")

    call_compile("compile_expression", "expression", false)

    get_token
    add_symbol(")")

    get_token
    add_symbol("{")

    call_compile("compile_statements", "statements", false)

    get_token
    add_symbol("}")

  end


  def compile_return(has_token)
    if !has_token
      get_token
    end

    if @token.value != "return"
      raise "Compile error. #{@token.value} is given instead of 'return'"
    end
    add_tag("keyword", @token.value)

    get_token
    if @token.value != ";"
      call_compile("compile_expression", "expression", true)
    end

    get_token
    add_symbol(";")

  end

  def compile_if(has_token)
    if !has_token
      get_token
    end

    if @token.value != "if"
      raise "Compile error. #{@token.value} is given instead of 'if'"
    end
    add_tag("keyword", @token.value)


    get_token
    add_symbol("(")

    call_compile("compile_expression", "expression", true)

    get_token
    add_symbol(")")

    get_token
    add_symbol("{")

    call_compile("compile_statements", "statements", false)

    get_token
    add_symbol("}")

    get_token
    if @token.value == "else"
      add_tag("keyword", @token.value)
      add_symbol("{")

      call_compile("compile_statements", "statements", false)

      get_token
      add_symbol("}")

      get_token
    end

    add_symbol(";")

  end

  def compile_expression(has_token)
    if !has_token
      get_token
    end

    call_compile("compile_term", "term", true)

    get_token
    while Ops.include?(@token.value)
      call_compile("compile_term", "term", true)
      get_token
    end

  end

  def compile_term(has_token)
    if !has_token
      get_token
    end

    get_token
    if @token.type == TokenType::INT_CONST ||
       @token.type == TokenType::STRING_CONST ||
       KeywordConst.include?(@token.value)

      @xmls.push(@token.to_xml)

    elsif ["-", "~"].include?(@token.value)

      add_tag("symbol", @token.value)

    elsif @token.value == "("

      add_symbol("(")
      call_compile("compile_expression", "expression", false)

    elsif @token.type == TokenType::IDENTIFIER

      add_tag("identifier", @token.value)

      if @next_token.value == "["
        get_token
        add_symbol("[")

        call_compile("compile_expression", "expression", false)

        get_token
        add_symbol("]")

      elsif @next_token.value == "("
        get_token
        add_symbol("(")

        call_compile("compile_expression_list", "expressionList", false)

        get_token
        add_symbol(")")

      elsif @next_token.value == "."

        get_token
        add_symbol(".")

        get_token
        add_tag("identifier", @token.value)

        get_token
        add_symbol("(")

        call_compile("compile_expression_list", "expressionList", false)

        get_token
        add_symbol(")")
      end
    end
  end

  def compile_expression_list(has_token)
    if !has_token
      get_token
    end

    if @token.value != ")"
      call_compile("compile_expression", "expression", true)

      get_token
      while @token.value != ","
        add_symbol(",")
        call_compile("compile_expression", "expression", false)

        get_token
      end
    end

  end

  def add_symbol(sym)
    if @token.value != sym
      raise "Compile error. #{@token.value} is given instead of #{sym}"
    end
    add_tag("symbol", sym)
  end

end
