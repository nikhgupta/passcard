require 'forwardable'

module Passcard
  class Reader
    extend Forwardable
    def_delegators :to_hash, :[], :has_key?

    def self.read_key_file(key, path)
      data = File.readlines(path)
      self.new(key, data[1...-1].join.strip)
    end

    attr_reader :opts, :grid

    def initialize(key, enc_text)
      secret, enc_text = key.sha512, enc_text
      @opts = Passcard.decrypt!(secret, enc_text)
      get_grid
    end

    def get_grid
      return @grid if @grid
      @grid = @opts.delete("grid")
      @grid = @grid.chars.each_slice(@opts["size"][1]).to_a
      @grid = Passcard::Grid.new(@grid)
    end

    def numeric_grid
      @grid.slice([0, 0], @opts["numeric"])
    end

    def alpha_grid
      ir = @opts["size"][0] - @opts["alpha"][0]
      ic = @opts["size"][1] - @opts["alpha"][1]
      @grid.slice([ir, ic], @opts["size"])
    end

    # Should be taken from all corners rather than the first:
    def random_grid(rows = 10, cols = 10)
      return Passcard::Grid.new([]) if rows * cols == 0
      return @grid if rows * cols >= @grid.length

      ir = rand(@opts["size"][0] - rows - 1).to_i
      ic = rand(@opts["size"][1] - cols - 1).to_i
      @grid.slice([ir, ic], [ir + rows, ic + cols])
    end

    def to_hash
      @opts.merge("grid" => @grid.to_str)
    end

    def to_s(*a, &b)
      return @grid.to_s unless Passcard.outputters.has_key?(:to_s)
      klass, method = Passcard.outputters[:to_s]
      klass.new(self).send(method, *a, &b) || @grid.to_s
    end

    def method_missing(m, *a, &b)
      if Passcard.outputters.include?(m)
        klass, method_name = Passcard.outputters[m]
        klass.new(self).send(method_name, *a, &b)
      elsif @grid.respond_to?(m)
        @grid.send(m, *a, &b)
      else
        super
      end
    end

    def respond_to?(*args)
      @grid.respond_to?(*args) || super
    end
  end
end
