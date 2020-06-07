require 'test/unit'
require './jack_tokenizer'


class TokenizerTest < Test::Unit::TestCase
  def setup
    @tokenizer = JackTokenizer.new
  end


  def test_comment
    input = "/* comment  */"
    @tokenizer.set_input(input)
    actual = @tokenizer.get_token()
    assert_equal(nil, actual)

    input = <<-EOS
        // comment
        int x;
    EOS
    @tokenizer.set_input(input)
    actual = @tokenizer.get_token()
    assert_equal("int", actual.value)

    actual = @tokenizer.get_token()
    assert_equal("x", actual.value)

    actual = @tokenizer.get_token()
    assert_equal(";", actual.value)

  end

  def test_token_type
    input = "abc"
    @tokenizer.set_input(input)
    actual = @tokenizer.get_token()
    assert_equal(TokenType::IDENTIFIER, actual.type)
    assert_equal("abc", actual.value)

    input = "123"
    @tokenizer.set_input(input)
    actual = @tokenizer.get_token()
    assert_equal(TokenType::INT_CONST, actual.type)
    assert_equal("123", actual.value)

    input = "class"
    @tokenizer.set_input(input)
    actual = @tokenizer.get_token()
    assert_equal(TokenType::KEYWORD, actual.type)
    assert_equal("class", actual.value)

    input = '"//class"'
    @tokenizer.set_input(input)
    actual = @tokenizer.get_token()
    assert_equal(TokenType::STRING_CONST, actual.type)
    assert_equal("//class", actual.value)

    input = '/'
    @tokenizer.set_input(input)
    actual = @tokenizer.get_token()
    assert_equal(TokenType::SYMBOL, actual.type)
    assert_equal("/", actual.value)

  end

  def test_no_space_tokens
    input = "abc/(3+4)"
    @tokenizer.set_input(input)

    actual = @tokenizer.get_token()
    assert_equal(TokenType::IDENTIFIER, actual.type)
    assert_equal("abc", actual.value)

    actual = @tokenizer.get_token()
    assert_equal(TokenType::SYMBOL, actual.type)
    assert_equal("/", actual.value)

    actual = @tokenizer.get_token()
    assert_equal(TokenType::SYMBOL, actual.type)
    assert_equal("(", actual.value)

    actual = @tokenizer.get_token()
    assert_equal(TokenType::INT_CONST, actual.type)
    assert_equal("3", actual.value)

    actual = @tokenizer.get_token()
    assert_equal(TokenType::SYMBOL, actual.type)
    assert_equal("+", actual.value)

    actual = @tokenizer.get_token()
    assert_equal(TokenType::INT_CONST, actual.type)
    assert_equal("4", actual.value)

    actual = @tokenizer.get_token()
    assert_equal(TokenType::SYMBOL, actual.type)
    assert_equal(")", actual.value)

    actual = @tokenizer.get_token()
    assert_equal(nil, actual)

  end

  def test_multiline_comment
    input = <<~EOS
    /*
    int x = 3;
    /**** hoge ***/
    ;
    EOS
    @tokenizer.set_input(input)

    actual = @tokenizer.get_token()
    assert_equal(TokenType::SYMBOL, actual.type)
    assert_equal(";", actual.value)

  end
end
