require 'test/unit'
require './assembler'

class TestLineParser < Test::Unit::TestCase

  def setup
    @parser = LineParser.new
  end

  def test_a_command_like
    print(@parser)
    actual = @parser.a_command_like?("@abc")
    assert_equal(actual, true)

    actual = @parser.a_command_like?("abc")
    assert_equal(actual, false)

    actual = @parser.a_command_like?("//@abc")
    assert_equal(actual, false)

    actual = @parser.a_command_like?("a@abc")
    assert_equal(actual, false)

    actual = @parser.a_command_like?("(abc)")
    assert_equal(actual, false)

  end

  def test_l_command_like
    actual = @parser.l_command_like?("@abc")
    assert_equal(actual, false)

    actual = @parser.l_command_like?("abc")
    assert_equal(actual, false)

    actual = @parser.l_command_like?("//@abc")
    assert_equal(actual, false)

    actual = @parser.l_command_like?("a@abc")
    assert_equal(actual, false)

    actual = @parser.l_command_like?("(abc)")
    assert_equal(actual, true)

    actual = @parser.l_command_like?("(123)")
    assert_equal(actual, true)

  end

  def test_c_command_like
    actual = @parser.c_command_like?("@abc")
    assert_equal(actual, false)

    actual = @parser.c_command_like?("abc")
    assert_equal(actual, true)

    actual = @parser.c_command_like?("//@abc")
    assert_equal(actual, false)

    actual = @parser.c_command_like?("a@abc")
    assert_equal(actual, true)

    actual = @parser.c_command_like?("(abc)")
    assert_equal(actual, false)

    actual = @parser.c_command_like?("(123)")
    assert_equal(actual, false)

    actual = @parser.c_command_like?("$.$:$_")
    assert_equal(actual, true)

    actual = @parser.c_command_like?("M=1")
    assert_equal(actual, true)

  end


  def test_comment
    actual = @parser.comment?("@abc")
    assert_equal(actual, false)

    actual = @parser.comment?("//xyz")
    assert_equal(actual, true)

  end

  def test_clear_spaces
    actual = @parser.clear_spaces(" a  bc ")
    assert_equal(actual, "abc")
  end

  def test_digits
    actual = @parser.digits?("123")
    assert_equal(actual, true)

    actual = @parser.digits?("abc")
    assert_equal(actual, false)

    actual = @parser.digits?("1bc")
    assert_equal(actual, false)

  end


  def test_symbol

    actual = @parser.symbol?("abc")
    assert_equal(actual, true)

    actual = @parser.symbol?("ABC")
    assert_equal(actual, true)

    actual = @parser.symbol?("$abc")
    assert_equal(actual, true)

    actual = @parser.symbol?("a23")
    assert_equal(actual, true)

    actual = @parser.symbol?(".:._:_$:$")
    assert_equal(actual, true)

    actual = @parser.symbol?("@123")
    assert_equal(actual, false)

    actual = @parser.symbol?("ab@")
    assert_equal(actual, false)

    actual = @parser.symbol?("123")
    assert_equal(actual, false)

    actual = @parser.symbol?("1bc")
    assert_equal(actual, false)

    actual = @parser.symbol?("(abc)")
    assert_equal(actual, false)

    actual = @parser.symbol?("ab/")
    assert_equal(actual, false)

  end

  def test_value
    actual = @parser.value?("abc")
    assert_equal(actual, true)

    actual = @parser.value?("123")
    assert_equal(actual, true)

    actual = @parser.value?("@abc")
    assert_equal(actual, false)

    actual = @parser.value?("1bc")
    assert_equal(actual, false)
  end


  def test_parse_a_command
    actual = @parser.parse_a_command("@abc")
    assert_equal(actual, "abc")

    actual = @parser.parse_a_command("@123")
    assert_equal(actual, "123")

    assert_raises RuntimeError do
       @parser.parse_a_command("@1bc")
    end

    assert_raises RuntimeError do
       @parser.parse_a_command("@@@@")
    end

    assert_raises RuntimeError do
       @parser.parse_a_command("(@abc)")
    end

  end

  def test_parse_l_command
    actual = @parser.parse_l_command("(abc)")
    assert_equal(actual, "abc")

    actual = @parser.parse_l_command("($abc)")
    assert_equal(actual, "$abc")


    assert_raises RuntimeError do
       @parser.parse_l_command("(123)")
    end

    assert_raises RuntimeError do
       @parser.parse_l_command("(@abc)")
    end

    assert_raises RuntimeError do
       @parser.parse_l_command("(abc")
    end

  end

  def test_parse_c_command
    actual = @parser.parse_c_command("A=0")
    assert_equal(actual, {"dest" => "A", "comp" => "0", "jump" => ""})

    actual = @parser.parse_c_command("0;JMP")
    assert_equal(actual, {"dest" => "", "comp" => "0", "jump" => "JMP"})

  end

  def test_parse
    actual = @parser.parse("@i")
    assert_equal(actual["command_type"], A_COMMAND)

    actual = @parser.parse("(Label)")
    assert_equal(actual["command_type"], L_COMMAND)

    actual = @parser.parse("M=1")
    assert_equal(actual["command_type"], C_COMMAND)

  end


  def test_c_mnemonic

    actual = @parser.c_mnemonic("M=1")
    assert_equal(actual, ["M", "1", ""])

    actual = @parser.c_mnemonic("A=A-1")
    assert_equal(actual, ["A", "A-1", ""])

    actual = @parser.c_mnemonic("D;JGE")
    assert_equal(actual, ["", "D", "JGE"])

    assert_raises RuntimeError do
      @parser.c_mnemonic("X;JGE")
    end

    assert_raises RuntimeError do
      @parser.c_mnemonic("A;JUMP")
    end

    assert_raises RuntimeError do
      @parser.c_mnemonic("M=2")
    end
  end

end


class TestParser < Test::Unit::TestCase

  def setup
    @lines = [
      "",
      "  //hoge",
      "  (label)",
      "  @i",
      "M=1",
      "@2",
      "@label2",
      "D=1",
      "(label2)"
    ]
    @parser = Parser.new({"lines" => @lines})
  end

  def test_has_more_command

    actual = @parser.has_more_command?
    assert_equal(true, actual)

    @lines.size.times{@parser.advance}

    actual = @parser.has_more_command?
    assert_equal(false, actual)

  end

  def test_advance

    @parser.advance
    actual = @parser.command_type
    assert_equal(NO_COMMAND, actual, @parser.cur_line)

    @parser.advance
    actual = @parser.command_type
    assert_equal(NO_COMMAND, actual, @parser.cur_line)

    @parser.advance
    actual = @parser.command_type
    assert_equal(L_COMMAND, actual, @parser.cur_line)

    @parser.advance
    actual = @parser.command_type
    assert_equal(A_COMMAND, actual, @parser.cur_line)

    @parser.advance
    actual = @parser.command_type
    assert_equal(C_COMMAND, actual, @parser.cur_line)

    @parser.advance
    actual = @parser.command_type
    assert_equal(A_COMMAND, actual, @parser.cur_line)


  end

  def test_symbol_table

    @lines.size.times{
      @parser.advance
      if @parser.command_type == L_COMMAND
        @parser.update_symbol_table
      end
    }

    @parser.seek_init

    @lines.size.times{
      @parser.advance
      @parser.update_symbol_table
    }

    actual = @parser.symbol_table.contains?("label")
    assert_equal(true, actual)

    actual = @parser.symbol_table.get_address("label")
    assert_equal("0", actual)

    actual = @parser.symbol_table.contains?("i")
    assert_equal(true, actual)

    actual = @parser.symbol_table.get_address("i")
    assert_equal("16", actual)

    actual = @parser.symbol_table.get_address("label2")
    assert_equal("5", actual)


    actual = @parser.symbol_table.get_address("label2")
    assert_equal("5", actual)


  end

  def test_code
    @lines.size.times{
      @parser.advance
      @parser.update_symbol_table
    }

    @parser.seek_init

    codes = []
    @lines.size.times{
      @parser.advance
      codes.push(@parser.get_code)
    }

    # ""
    assert_equal(nil, codes[0])
    # //hoge
    assert_equal(nil, codes[1])
    # (label)
    assert_equal(nil, codes[2])
    # @i
    assert_equal("0000000000010000", codes[3])
    # M=1
    assert_equal("1110111111001000", codes[4])
    # @2
    assert_equal("0000000000000010", codes[5])

  end
end
