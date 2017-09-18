require "yaml"

require "passe/version"
require "passe/generator"
require "passe/option_parser"

module Passe
  class Error < StandardError; end

  # Defaults to use.
  NUM_ROWS    = 30 # percent of total rows
  ALGORITHMS  = %w[MD5 SHA1 SHA256 SHA384 SHA512]
  CS_ALPHANUM = "23456789abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ"
  CS_ALNUMSYM = '23456789abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ'+
                '@#$%&*<>?-+{}[]()\/'
  HEADERS     = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789αβγδλθμπσ"+
                "☀ ☂ ★ ☎ ☯ ☾ ♞ ♡ ♢ ♤ ♧ ♫ ✈"

  def self.root
    Pathname.new(File.dirname(File.dirname(__FILE__)))
  end
end
