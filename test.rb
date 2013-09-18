require 'minitest/unit'
load "git-grep-token-ruby"

MiniTest::Unit.autorun

def parse(code)
  ast = Parser::CurrentRuby.parse(code)
  if ast.type != :begin
    AST::Node.new(:begin, [ast])
  else
    ast
  end
end

class TestFoo < MiniTest::Unit::TestCase
  def test_def
    loc = extract(parse(<<-CODE), :foo)
def foo(x, y, z, *args)
  :foo
end
    CODE
    assert_equal [[1, 3]], loc
  end

  def test_def_in_class
    loc = extract(parse(<<-CODE), :foo)
class Foo
  def foo
    :foo
  end
end
    CODE
    assert_equal [[2, 4]], loc
  end

  def test_def_in_def
    loc = extract(parse(<<-CODE), :foo)
def baz
  def foo
    :bazfoo
  end
end
    CODE
    assert_equal [[2, 4]], loc
  end

  def test_simple_call
    loc = extract(parse(<<-CODE), :foo)
foo
    CODE
    assert_equal [[1, 1]], loc
  end

  def test_call_with_parens
    loc = extract(parse(<<-CODE), :foo)
foo(1,
    1)
    CODE
    assert_equal [[1, 2]], loc
  end

  def test_without_parens
    loc = extract(parse(<<-CODE), :foo)
foo 1,
    2,
    3
    CODE
    assert_equal [[1, 3]], loc
  end

  def test_nest_call
    loc = extract(parse(<<-CODE), :foo)
bar(foo(1))
    CODE
    assert_equal [[1, 1]], loc
  end

  def test_nest_call2
    loc = extract(parse(<<-CODE), :foo)
bar(
 foo(1),
 foo(2)
)
    CODE
    assert_equal [[2, 2], [3, 3]], loc
  end

  def test_call_with_block
    loc = extract(parse(<<-CODE), :foo)
foo 1 do
  :block
end
    CODE
    assert_equal [[1, 3]], loc
  end

  def test_assign
    loc = extract(parse(<<-CODE), :foo)
foo = 1,
      2
    CODE
    assert_equal [[1, 2]], loc
  end

  def test_heredoc
    loc = extract(parse(<<-CODE), :foo)
foo(<<HEREDOC)
HEREDOC
    CODE
    assert_equal [[1, 2]], loc
  end

  def test_heredoc_enclosed_in_parens
    loc = extract(parse(<<-CODE), :foo)
foo(<<HEREDOC
HEREDOC
)

foo(<<HEREDOC
heredoc
HEREDOC
)
    CODE
    assert_equal [[1, 3], [5, 8]], loc
  end

  def test_heredocs
    loc = extract(parse(<<-CODE), :foo)
foo(<<HEREDOC, <<HEREDOD)
HEREDOC
HEREDOD

foo(<<HEREDOC, <<HEREDOD)
heredoc
HEREDOC
heredod
HEREDOD
    CODE
    assert_equal [[1, 3], [5, 9]], loc
  end

  def test_heredocs_and_block
    loc = extract(parse(<<-CODE), :foo)
foo(<<HEREDOC, <<HEREDOD) do
heredoc
HEREDOC
heredod
HEREDOD
  :block_body
end
    CODE
    assert_equal [[1, 7]], loc
  end

  def test_assign_heredoc
    loc = extract(parse(<<-CODE), :foo)
foo = <<HEREDOC
HEREDOC
    CODE
    assert_equal [[1, 2]], loc
  end
end
