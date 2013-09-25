require 'minitest/unit'
load "git-grep-token-ruby"

MiniTest::Unit.autorun

def parse(code)
  Parser::CurrentRuby.parse(code)
end

def get_start_and_end(extracteds)
  extracteds.map do |(start_loc, end_loc)|
    [start_loc.begin_pos, end_loc.end_pos]
  end
end

class TestFoo < MiniTest::Unit::TestCase
  def test_def
    loc = extract(parse(<<-CODE), :foo)
def foo(x, y, z, *args)
  :foo
end
    CODE
    assert_equal [[0, 34]], get_start_and_end(loc)
  end

  def test_def_in_class
    loc = extract(parse(<<-CODE), :foo)
class Foo
  def foo
    :foo
  end
end
    CODE
    assert_equal [[12, 34]], get_start_and_end(loc)
  end

  def test_def_in_def
    loc = extract(parse(<<-CODE), :foo)
def baz
  def foo
    :bazfoo
  end
end
    CODE
    assert_equal [[10, 35]], get_start_and_end(loc)
  end

  def test_simple_call
    loc = extract(parse(<<-CODE), :foo)
foo
    CODE
    assert_equal [[0, 3]], get_start_and_end(loc)
  end

  def test_call_with_parens
    loc = extract(parse(<<-CODE), :foo)
foo(1,
    1)
    CODE
    assert_equal [[0, 13]], get_start_and_end(loc)
  end

  def test_without_parens
    loc = extract(parse(<<-CODE), :foo)
foo 1,
    2,
    3
    CODE
    assert_equal [[0, 19]], get_start_and_end(loc)
  end

  def test_nest_call
    loc = extract(parse(<<-CODE), :foo)
bar(foo(1))
    CODE
    assert_equal [[4, 10]], get_start_and_end(loc)
  end

  def test_nest_call2
    loc = extract(parse(<<-CODE), :foo)
bar(
 foo(1),
 foo(2)
)
    CODE
    assert_equal [[6, 12], [15, 21]], get_start_and_end(loc)
  end

  def test_call_with_block
    loc = extract(parse(<<-CODE), :foo)
foo 1 do
  :block
end
    CODE
    assert_equal [[0, 21]], get_start_and_end(loc)
  end

  def test_assign
    loc = extract(parse(<<-CODE), :foo)
foo = 1,
      2
    CODE
    assert_equal [[0, 16]], get_start_and_end(loc)
  end

  def test_heredoc
    loc = extract(parse(<<-CODE), :foo)
foo(<<HEREDOC)
HEREDOC
    CODE
    assert_equal [[0, 22]], get_start_and_end(loc)
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
    assert_equal [[0, 23], [24, 55]], get_start_and_end(loc)
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
    assert_equal [[0, 41], [42, 99]], get_start_and_end(loc)
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
    assert_equal [[0, 78]], get_start_and_end(loc)
  end

  def test_assign_heredoc
    loc = extract(parse(<<-CODE), :foo)
foo = <<HEREDOC
HEREDOC
    CODE
    assert_equal [[0, 23]], get_start_and_end(loc)
  end

  def test_nest_heredocs
    loc = extract(parse(<<-'CODE'), :foo)
foo(<<HEREDOC)
#{<<HEREDOD}
heredod
HEREDOD
heredoc
HEREDOC
    CODE
    assert_equal [[0, 59]], get_start_and_end(loc)
  end

  def test_heredoc_in_str
    loc = extract(parse(<<-'CODE'), :foo)
foo("#{<<HEREDOC}")
heredoc
HEREDOC
    CODE
    assert_equal [[0, 35]], get_start_and_end(loc)
  end
end
