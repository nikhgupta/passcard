module Passe
  class Outputter
    HEADERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789 αβγδθλμπϕ $£¥€¢' + # 50
      '! # % & * < = > ? @ ✓ ∞ ♬ ♡ ♢ ♤ ♧ ☯ ☾ ✈ ☎ ☀ ☁ ☂ ☃ ★ ⌘ ♞  ✂ ✎ '   # 30

    attr_accessor :reader, :grid, :palette

    def initialize(reader)
      self.reader = reader
      self.palette = Passe::Palette.new
    end

    # Register one or more handler methods with this outputter.
    # Passe will then be able to use these methods to get the output
    # from the outputter. For example, if you have an HtmlOutputter,
    # you could do:
    #
    #   register :to_html, :to_xml
    #
    # You could then do a Passe.to_png and get the result of that method.
    # The class which registers the method will receive the generator instance
    # as the only argument, and the default implementation of initialize puts
    # that into the +passe+ accessor.
    #
    # You can also have different method names in the outputter by providing
    # a hash:
    #
    #   register to_html: :create_html, to_xml: :create_xml
    #
    def self.register(*args)
      hash = args.last.is_a?(Hash) ? args.pop : {}
      raise Passe::Error, "You must register a method name!" if args.empty? && hash.empty?
      args.each{|name| hash[name] = name}
      hash.each do |name, method_name|
        ::Passe.register_outputter(name, self, method_name)
      end
    end

    def use_palette(type, options = {})
      options.merge!("n" => @grid.row_size) if @grid
      self.palette.type = type
      self.palette.options = options
    end

    def row_headers
      headers   = self.class.const_get("ROW_HEADERS") rescue nil
      headers ||= self.class.const_get("HEADERS")
      headers.gsub(/ /, '').chars.take(grid.row_size)
    end

    def col_headers
      headers   = self.class.const_get("COLUMN_HEADERS") rescue nil
      headers ||= self.class.const_get("HEADERS")
      headers.gsub(/ /, '').chars.take(grid.col_size)
    end

    def get_grid(options = {})
      random = options[:type].to_s.to_sym == :random
      coordinates = get_grid_coordinates(options)
      @grid = reader.random_grid(20, 30) if  random
      @grid = reader.slice(*coordinates) if !random
      use_palette :passe
      @grid
    end

    def data_in(file)
      content = File.read(file)
      regex   = /^\s*__END__\s*$/
      return "" if content.match(regex).nil?
      content.split(regex).last.strip
    end

    private

    def get_grid_coordinates(options = {})
      case options[:type].to_s.to_sym
      when :pincard      then [[ 0, 0], [10,20]]  # 10x20 numbers only
      when :pincard_alt  then [[10, 0], [20,20]]  # 10x20 numbers only (alt)
      when :alphanum     then [[40,40], [66,66]]  # 26x26 alphanumeric only
      when :alphanum_alt then [[54,54], [80,80]]  # 26x26 alphanumeric only (alt)
      when :square       then [[20,20], [40,40]]  # 20x20 alphanum & symbols
      when :card_large   then [[ 0,20], [15,50]]  # 15x30 alphanum & symbols
      when :card         then [[30,20], [40,40]]  # 10x20 alphanum & symbols - card
      else [[0,0], [80,80]]
      end
    end
  end
end
