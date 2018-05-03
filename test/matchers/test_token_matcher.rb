# frozen_string_literal: true

require 'minitest/autorun'
require 'grep_ruby_token'
require 'test_helper'

class TestTokenMatcher < MiniTest::Test
  def test_send_with_block?
    matcher = GrepRubyToken::Matchers::TokenMatcher.new(:dummy)

    node = parse('obj.call')
    refute(matcher.send(:send_with_block?, node))

    node = parse('obj.call { foo }')
    assert(matcher.send(:send_with_block?, node))
  end

  def test_match?
    matcher = GrepRubyToken::Matchers::TokenMatcher.new(:needle)

    assert(matcher.match?(parse('needle')))
    assert(matcher.match?(parse("needle { 'with block' }")))

    refute(matcher.match?(parse('thread')))
    refute(matcher.match?(parse("thread { 'with block' }")))
  end
end
