# frozen_string_literal: true

def parse(code)
  Parser::CurrentRuby.parse(code)
end
