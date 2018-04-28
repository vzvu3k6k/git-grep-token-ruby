#!/usr/bin/env ruby
# frozen_string_literal: true

require 'parser/current'
require 'shellwords'

module GrepRubyToken
  module_function

  def search(node, return_when_finding: true, &block)
    result = []
    return result unless node.is_a?(Parser::AST::Node)

    if block.call(node)
      result << node
      return result if return_when_finding
    end

    node.children.each.with_object(result) do |child, result|
      result.concat(search(child, return_when_finding: return_when_finding, &block))
    end
  end

  def extract(ast, matcher)
    search(ast) { |node| matcher.match?(node) }.map do |node|
      last_heredoc_pos = search(node, return_when_finding: false) { |c| (c.type == :dstr || c.type == :str) }
                         .map do |node|
        loc = node.loc
        loc.respond_to?(:heredoc_end) ? loc.heredoc_end : loc.expression
      end.max_by(&:end_pos)

      start = node.loc.expression
      finish = [last_heredoc_pos, node.loc.expression].compact.max_by(&:end_pos)
      [start, finish, node]
    end
  end

  def token_grep(file, code, matcher)
    ast = Parser::CurrentRuby.parse(code)

    extract(ast, matcher).map do |(expression_start, expression_finish, node)|
      start_line_num = expression_start.begin.line
      line_start = expression_start.begin_pos.downto(0).find { |i| code[i] == "\n" }
      line_start = line_start.nil? ? 0 : line_start + 1
      line_finish = (expression_finish.end_pos - 1).upto(code.size - 1).find { |i| code[i] == "\n" }

      token_positions = search(node, return_when_finding: false) do |node|
        matcher.match?(node)
      end.map do |node|
        %i[name selector].find do |prop|
          break node.loc.send(prop)
        rescue StandardError
          next
        end.tap do |position|
          warn "Can't determine which property locates the token:\n#{node.loc}" if position.nil?
        end
      end.compact.sort_by(&:begin_pos)

      fragment = code[line_start..line_finish]
      prefix = "\x1b[01;31m"
      suffix = "\x1b[0m"
      offset_unit = prefix.size + suffix.size
      token_positions.each_with_index do |wp, idx|
        base_offset = offset_unit * idx
        fragment[wp.begin_pos - line_start + base_offset, 0] = prefix
        fragment[wp.end_pos - line_start + base_offset + prefix.size, 0] = suffix
      end

      highlighted_fragment = fragment.each_line.map.with_index do |line, idx|
        "#{format('%6d', start_line_num + idx)}  #{line}"
      end.to_a.join

      "#{file}:#{start_line_num}\n" + highlighted_fragment
    end.join("\n")
  end
end
