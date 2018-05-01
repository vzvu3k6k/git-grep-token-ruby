# frozen_string_literal: true

require 'minitest/autorun'
require 'grep_ruby_token'
require 'test_helper'

class TestExtract < MiniTest::Test
  def test_def
    assert_extract(<<~CODE, :foo)
      ≤def foo(x, y, z, *args)
        :foo
      end≥
    CODE
  end

  def test_def_in_class
    assert_extract(<<~CODE, :foo)
      class Foo
        ≤def foo
          :foo
        end≥
      end
    CODE
  end

  def test_def_in_def
    assert_extract(<<~CODE, :foo)
      def baz
        ≤def foo
          :bazfoo
        end≥
      end
    CODE
  end

  def test_simple_call
    assert_extract('≤foo≥', :foo)
  end

  def test_call_with_parens
    assert_extract(<<~CODE, :foo)
      ≤foo(1,
          1)≥
    CODE
  end

  def test_call_without_parens
    assert_extract(<<~CODE, :foo)
      ≤foo 1,
          2,
          3≥
    CODE
  end

  def test_nested_call
    assert_extract(<<~CODE, :foo)
      bar(≤foo(1)≥)
    CODE
  end

  def test_nested_call_with_multiple_arguments
    assert_extract(<<~CODE, :foo)
      bar(
       ≤foo(1)≥,
       ≤foo(2)≥,
       baz(3)
      )
    CODE
  end

  def test_call_with_block
    assert_extract(<<~CODE, :foo)
      ≤foo 1 do
        :block
      end≥
    CODE
  end

  def test_assign
    assert_extract(<<~CODE, :foo)
      ≤foo = 1,
            2≥
    CODE
  end

  def test_heredoc
    assert_extract(<<~CODE, :foo)
      ≤foo(<<HEREDOC)
      HEREDOC≥
    CODE
  end

  def test_heredoc_enclosed_in_parens
    assert_extract(<<~CODE, :foo)
      ≤foo(<<HEREDOC
      HEREDOC
      )≥
      ≤foo(<<HEREDOC
      heredoc
      HEREDOC
      )≥
    CODE
  end

  def test_heredocs
    assert_extract(<<~CODE, :foo)
      ≤foo(<<HEREDOC, <<HEREDOD)
      HEREDOC
      HEREDOD≥
      ≤foo(<<HEREDOC, <<HEREDOD)
      heredoc
      HEREDOC
      heredod
      HEREDOD≥
    CODE
  end

  def test_heredocs_and_block
    assert_extract(<<~CODE, :foo)
      ≤foo(<<HEREDOC, <<HEREDOD) do
      heredoc
      HEREDOC
      heredod
      HEREDOD
        :block_body
      end≥
    CODE
  end

  def test_assign_heredoc
    assert_extract(<<~CODE, :foo)
      ≤foo = <<HEREDOC
      HEREDOC≥
    CODE
  end

  def test_nested_heredocs
    extract(<<~'CODE', :foo)
      ≤foo(<<HEREDOC)
      #{<<HEREDOD}
      heredod
      HEREDOD
      heredoc
      HEREDOC≥
    CODE
  end

  def test_heredoc_in_str
    extract(<<~'CODE', :foo)
      ≤foo("#{<<HEREDOC}")
      heredoc
      HEREDOC≥
    CODE
  end

  private

  def get_start_and_end(locations)
    locations.map do |(start_loc, end_loc)|
      [start_loc.begin_pos, end_loc.end_pos]
    end
  end

  def extract(code, token)
    GrepRubyToken.extract(code, token)
  end

  def assert_extract(annotated_code, token)
    expected_locations, code = parse_annotated_code(annotated_code)
    actual_locations = extract(parse(code), token)
    assert_equal expected_locations, get_start_and_end(actual_locations)
  end

  def parse_annotated_code(annotated_code)
    offset = 0
    locations = []
    annotated_code.each_char.with_index do |char, index|
      case char
      when '≤'
        locations << [index - offset]
        offset += 1
      when '≥'
        locations.last << index - offset
        offset += 1
      end
    end
    [locations, annotated_code.tr('≤≥', '')]
  end
end

class TestTokenGrep < MiniTest::Test
  def token_grep(code, token)
    GrepRubyToken.token_grep('', code, token)
  end

  def test_multiple_tokens
    assert_equal token_grep(<<~CODE, :foo), ":1\n     1  \e[01;31mfoo\e[0m({bar: true}).\e[01;31mfoo\e[0m.\e[01;31mfoo\e[0m\n"
      foo({bar: true}).foo.foo
CODE
  end
end
