require 'test/unit'
require './compilation_engine'


class TokenizerTest < Test::Unit::TestCase
  def setup
    @tokenizer = JackTokenizer.new
    @engine = CompilationEngine.new(@tokenizer)
  end



  def test_simple_class

    input = <<-EOS
    class Simple {

    }
    EOS

    expected = <<~EOS
    <class>
    <keyword> class </keyword>
    <identifier> Simple </identifier>
    <symbol> { </symbol>
    <symbol> } </symbol>
    </class>
    EOS


    @engine.reset(input)
    @engine.compile
    actual = @engine.dump_xml()
    assert_equal(expected.strip, actual.strip)

  end

  def test_class_var_dec

    input = <<-EOS
    static int classVar1;
    EOS

    expected = <<~EOS
    <classVarDec>
    <keyword> static </keyword>
    <keyword> int </keyword>
    <identifier> classVar1 </identifier>
    <symbol> ; </symbol>
    </classVarDec>
    EOS
    @engine.reset(input)
    @engine.compile
    actual = @engine.dump_xml()
    assert_equal(expected.strip, actual.strip)

    input = <<-EOS
    static int classVar1 , classVar2;
    EOS

    expected = <<~EOS
    <classVarDec>
    <keyword> static </keyword>
    <keyword> int </keyword>
    <identifier> classVar1 </identifier>
    <symbol> , </symbol>
    <identifier> classVar2 </identifier>
    <symbol> ; </symbol>
    </classVarDec>
    EOS
    @engine.reset(input)
    @engine.compile
    actual = @engine.dump_xml()
    assert_equal(expected.strip, actual.strip)

  end

  def test_subroutine_dec_no_statements

    input = <<-EOS
    function void func(){}
    EOS

    expected = <<~EOS
    <subroutineDec>
    <keyword> function </keyword>
    <keyword> void </keyword>
    <identifier> func </identifier>
    <symbol> ( </symbol>
    <parameterList>
    </parameterList>
    <symbol> ) </symbol>
    <subroutineBody>
    <symbol> { </symbol>
    <statements>
    </statements>
    <symbol> } </symbol>
    </subroutineBody>
    </subroutineDec>
    EOS

    @engine.reset(input)
    @engine.compile
    actual = @engine.dump_xml()
    assert_equal(expected.strip, actual.strip)

    input = <<-EOS
    function void func(int i){}
    EOS

    expected = <<~EOS
    <subroutineDec>
    <keyword> function </keyword>
    <keyword> void </keyword>
    <identifier> func </identifier>
    <symbol> ( </symbol>
    <parameterList>
    <keyword> int </keyword>
    <identifier> i </identifier>
    </parameterList>
    <symbol> ) </symbol>
    <subroutineBody>
    <symbol> { </symbol>
    <statements>
    </statements>
    <symbol> } </symbol>
    </subroutineBody>
    </subroutineDec>
    EOS


    @engine.reset(input)
    @engine.compile
    actual = @engine.dump_xml()
    assert_equal(expected.strip, actual.strip)

    input = <<-EOS
    function void func(int i, boolean is_ok){}
    EOS

        expected = <<~EOS
    <subroutineDec>
    <keyword> function </keyword>
    <keyword> void </keyword>
    <identifier> func </identifier>
    <symbol> ( </symbol>
    <parameterList>
    <keyword> int </keyword>
    <identifier> i </identifier>
    <symbol> , </symbol>
    <keyword> boolean </keyword>
    <identifier> is_ok </identifier>
    </parameterList>
    <symbol> ) </symbol>
    <subroutineBody>
    <symbol> { </symbol>
    <statements>
    </statements>
    <symbol> } </symbol>
    </subroutineBody>
    </subroutineDec>
    EOS

    @engine.reset(input)
    @engine.compile
    actual = @engine.dump_xml()
    assert_equal(expected.strip, actual.strip)

  end


  def test_subroutine_statements
    input = <<-EOS
    function void func(){
        var int x, y;
        let sum = x + y;

        if (x < y) {
        return 0;
        }

        while (i > 0) {
        do add (x + y);
        }
    }
    EOS

    expected = <<~EOS
    <subroutineDec>
    <keyword> function </keyword>
    <keyword> void </keyword>
    <identifier> func </identifier>
    <symbol> ( </symbol>
    <parameterList>
    </parameterList>
    <symbol> ) </symbol>
    <subroutineBody>
    <symbol> { </symbol>
    <varDec>
    <keyword> var </keyword>
    <keyword> int </keyword>
    <identifier> x </identifier>
    <symbol> , </symbol>
    <identifier> y </identifier>
    <symbol> ; </symbol>
    </varDec>
    <statements>
    <letStatement>
    <keyword> let </keyword>
    <identifier> sum </identifier>
    <symbol> = </symbol>
    <expression>
    <term>
    <identifier> x </identifier>
    </term>
    <symbol> + </symbol>
    <term>
    <identifier> y </identifier>
    </term>
    </expression>
    <symbol> ; </symbol>
    </letStatement>
    <ifStatement>
    <keyword> if </keyword>
    <symbol> ( </symbol>
    <expression>
    <term>
    <identifier> x </identifier>
    </term>
    <symbol> &lt; </symbol>
    <term>
    <identifier> y </identifier>
    </term>
    </expression>
    <symbol> ) </symbol>
    <symbol> { </symbol>
    <statements>
    <returnStatement>
    <keyword> return </keyword>
    <expression>
    <term>
    <integerConstant> 0 </integerConstant>
    </term>
    </expression>
    <symbol> ; </symbol>
    </returnStatement>
    </statements>
    <symbol> } </symbol>
    </ifStatement>
    <whileStatement>
    <keyword> while </keyword>
    <symbol> ( </symbol>
    <expression>
    <term>
    <identifier> i </identifier>
    </term>
    <symbol> &gt; </symbol>
    <term>
    <integerConstant> 0 </integerConstant>
    </term>
    </expression>
    <symbol> ) </symbol>
    <symbol> { </symbol>
    <statements>
    <doStatement>
    <keyword> do </keyword>
    <identifier> add </identifier>
    <symbol> ( </symbol>
    <expressionList>
    <expression>
    <term>
    <identifier> x </identifier>
    </term>
    <symbol> + </symbol>
    <term>
    <identifier> y </identifier>
    </term>
    </expression>
    </expressionList>
    <symbol> ) </symbol>
    <symbol> ; </symbol>
    </doStatement>
    </statements>
    <symbol> } </symbol>
    </whileStatement>
    </statements>
    <symbol> } </symbol>
    </subroutineBody>
    </subroutineDec>
    EOS

    @engine.reset(input)
    @engine.compile
    actual = @engine.dump_xml()
    assert_equal(expected.strip, actual.strip)

  end

end
