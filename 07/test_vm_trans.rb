require 'test/unit'
require './vm_trans'

class TestLineParser < Test::Unit::TestCase
  def setup
    @parser = LineParser.new
  end

end


class TestCodeWriter < Test::Unit::TestCase

  def setup
    @cw = CodeWriter.new
  end

  def test_init
    puts @cw.make_init()
  end

  def test_arithmetic
    puts @cw.make_arithmetic("add")
  end

  def test_memory

    puts @cw.make_push(C_PUSH, "local", "0")
    puts @cw.make_push(C_PUSH, "pointer", "1")
    puts @cw.make_push(C_PUSH, "constant", "2")

    puts @cw.make_pop(C_POP, "local", "0")
    puts @cw.make_pop(C_POP, "pointer", "1")
  end

end
