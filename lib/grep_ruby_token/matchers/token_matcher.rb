module GrepRubyToken
  module Matchers
    class TokenMatcher
      attr_reader :word

      def initialize(word)
        @word = word
      end

      def match?(node)
        if send_with_block?(node)
          node.children[0].children[1] == word
        else
          node.children.any? { |c| c == word }
        end
      end

      private

      def send_with_block?(node)
        node.type == :block && node.children[0].type == :send
      end
    end
  end
end
