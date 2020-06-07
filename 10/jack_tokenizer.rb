module TokenType
  KEYWORD = 1
  SYMBOL = 2
  IDENTIFIER = 3
  INT_CONST = 4
  STRING_CONST = 5
end

Keywords = {
  "class" => "CLASS",
  "method" => "METHOD",
  "function" => "FUNCTION",
  "constructor" => "CONSTRUCTOR",
  "int" => "INT",
  "boolean" => "BOOLEAN",
  "char" => "CHAR",
  "void" => "VOID",
  "static" => "STATIC",
  "field" => "FIELD",
  "let" => "LET",
  "do" => "DO",
  "if" => "IF",
  "else" => "ELSE",
  "while" => "WHILE",
  "return" => "RETURN",
  "true" => "TRUE",
  "false" => "FALSE",
  "null" => "NULL",
  "this" => "THIS",
}

Symbols = ["{", "}", "(", ")", "[", "]", ".", ",", ";",
           "+", "-", "*", "/", "&", "|", "<", ">", "=", "~"]

class Token
  attr_reader :value, :type

  def initialize(value:, type:)
    @value = value
    @type = type
  end

  def to_xml

    case @type
    when TokenType::KEYWORD
      tag = "keyword"
    when TokenType::SYMBOL
      tag = "symbol"
    when TokenType::IDENTIFIER
      tag = "identifier"
    when TokenType::INT_CONST
      tag = "integerConstant"
    when TokenType::STRING_CONST
      tag = "stringConstant"
    end

    "<#{tag}> #{value} </#{tag}>"

  end
end


class JackTokenizer

  def initialize()
  end

  def set_input(input)
    @input_chars = input.chars
    @index = 0
  end

  def reset_index
    @index = 0
  end

  def pop_char
    if @index < @input_chars.size
      ch = @input_chars[@index]
      @index += 1
      return ch
    else
      return nil
    end
  end

  def peek_next_char
    if @index < @input_chars.size
      return @input_chars[@index]
    else
      return nil
    end
  end

  def back_char
    if @index > 0
      @index -= 1
    end
  end

  def get_token()
    buf = []
    state = nil

    while ch = pop_char

      if state.nil?

        if ch =~ /\s/
          next
        end

        if ch == "/"
          if peek_next_char == "/"
            pop_char
            state = :comment
            next
          elsif peek_next_char == "*"
            pop_char
            state = :multi_comment
            next
          else
            return Token.new(value: ch, type: TokenType::SYMBOL)
          end
        elsif ch == "\""

          state = :string
          next

        elsif ch =~ /\d/

          state = :digit
          buf.push(ch)
          next

        elsif Symbols.include?(ch)

          # ch is Symbol except for "/"
          return Token.new(value: ch, type: TokenType::SYMBOL)

        elsif ch =~ /[_a-zA-Z]/

          state = :id
          buf.push(ch)
          next

        else
          raise "Unknow char #{ch}!"
        end
      elsif state == :comment
        if ch == "\n"
          state = nil
          buf = []
          next
        else
          buf.push(ch)
          next
        end
      elsif state == :multi_comment
        if ch == "*" && peek_next_char == "/"
          pop_char
          state = nil
          buf = []
          next
        else
          buf.push(ch)
          next
        end
      elsif state == :string
        if ch == "\""
          return Token.new(value: buf.join(""), type:TokenType::STRING_CONST)
        elsif ch == "\n"
          raise "Invalid String Constatnt #{buf.join("")}"
        else
          buf.push(ch)
          next
        end
      elsif state == :digit
        if ch =~ /\s/
          return Token.new(value: buf.join(""), type:TokenType::INT_CONST)
        elsif ch =~ /\d/
          buf.push(ch)
          if peek_next_char == nil
            return Token.new(value: buf.join(""), type:TokenType::INT_CONST)
          else
            next
          end
        elsif Symbols.include?(ch)
          # Since symbols just after digit (ex. 123*4) is valid token,
          # rewind char index and return only the first digits.
          back_char
          return Token.new(value: buf.join(""), type:TokenType::INT_CONST)
        else
          raise "Invalid int Constatnt #{buf.join("")}"
        end
      elsif state == :id
        if ch =~ /\s/
          return get_keyword_or_identifier(buf.join(""))
        elsif Symbols.include?(ch)
          # Since symbols just after identifier (ex. i*4) is valid token,
          # rewind char index and return only the first identifier.
          back_char
          return get_keyword_or_identifier(buf.join(""))
        elsif ch =~ /[_a-zA-Z0-9]/
          buf.push(ch)
          if peek_next_char == nil
            return get_keyword_or_identifier(buf.join(""))
          else
            next
          end
        else
          raise "Invalid Identifier #{buf.join("")}"
        end
      end
    end

    return nil

  end

  def get_keyword_or_identifier(str)
    if Keywords.include? str
      return Token.new(value: str, type: TokenType::KEYWORD)
    else
      return Token.new(value: str, type: TokenType::IDENTIFIER)
    end
  end

  def dump_xml
    xmls = ["<tokens>"]
    while token = get_token
      xmls.push(token.to_xml)
    end

    xmls.push("</tokens>")

    return xmls.join("\n")
  end
end
