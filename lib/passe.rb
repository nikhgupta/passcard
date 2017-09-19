require "json"
require "base64"
require "openssl"
require "ostruct"

module Passe
  GRID_SIZE    = [80, 80]
  ALPHA_GRID   = [40, 40]
  NUMERIC_GRID = [20, 20]
  CHARSET = '0123456789abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ@#$%&*<>?-+{}[]()\/'

  class Error < StandardError; end

  def self.root
    Pathname.new(File.dirname(File.dirname(__FILE__)))
  end

  def self.outputters
    @@outputters ||= {}
  end

  def self.register_outputter(name, klass, method_name)
    @@outputters ||= {}
    @@outputters[name.to_sym] = [klass, method_name.to_sym]
  end

  def self.unregister_outputter(name)
    @@outputters.delete(name.to_sym)
  end

  def self.outputter_class_for(name)
    klass = outputters[name.to_sym].first
    return klass if klass.is_a?(Class)
    Kernel.const_get(klass.to_s)
  end

  def self.encrypt!(key, object)
    object = object.to_json
    cipher = OpenSSL::Cipher.new('DES-EDE3-CBC').encrypt
    cipher.key = Random.new(key.to_i(36)).bytes(24)
    output = cipher.update(object) + cipher.final
    Base64.encode64(output)
  end

  def self.decrypt!(key, enc_str)
    cipher     = OpenSSL::Cipher.new('DES-EDE3-CBC').decrypt
    cipher.key = Random.new(key.to_i(36)).bytes(24)
    decrypted  = cipher.update(Base64.decode64(enc_str))
    output     = decrypted << cipher.final
    JSON.parse(output)
  end

  def self.create!(*args)
    Passe::Generator.create_key_file(*args)
  end

  def self.read!(*args)
    Passe::Reader.read_key_file(*args)
  end
end

Dir.glob(Passe.root.join("lib", "extensions", "*.rb")){|f| require f}
require "passe/version"
require "passe/grid"
require "passe/generator"
require "passe/reader"
require "passe/palette"
require "passe/outputter"
require "passe/outputter/ascii_outputter"
