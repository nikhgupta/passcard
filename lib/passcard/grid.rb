require 'forwardable'

module Passcard
  class Grid
    extend Forwardable
    def_delegators :to_str, :chars, :gsub
    def_delegators :@arr, :take, :empty?, :first, :last

    def initialize(arr)
      @arr = arr
      raise_if_invalid_array!
    end

    def ==(g2)
      self.to_a == g2.to_a && g2.is_a?(self.class)
    end

    def [](*args)
      self.rows_at(*args)
    end

    def row_size
      @arr.size
    end

    def col_size
      @arr.any? ? @arr[0].size : 0
    end

    def size
      [row_size, col_size]
    end

    def length
      row_size * col_size
    end

    def rows_at(*rows)
      rows = rows.map{|a| a.respond_to?(:to_a) ? a.to_a : a}
      self.class.new rows.flatten.map{|a| @arr[a % @arr.size]}
    end

    def cols_at(*cols)
      cols = cols.map{|a| a.respond_to?(:to_a) ? a.to_a : a}
      self.class.new @arr.map{|a| cols.flatten.map{|c| a[c % a.length]}}
    end

    def at(rows: [], cols: [])
      return self if rows.empty? && cols.empty?
      return self.rows_at(*rows) if cols.empty?
      return self.cols_at(*cols) if rows.empty?
      self.rows_at(*rows).cols_at(*cols)
    end

    def slice(coord1, coord2)
      self.rows_at(coord1[0]...coord2[0]).cols_at(coord1[1]...coord2[1])
    end

    def transpose
      self.class.new @arr.transpose
    end

    def numeric?
      to_str =~ /\A[0-9]+\z/
    end

    def alphanumeric?
      to_str =~ /\A[a-z0-9]+\z/i
    end

    def has_symbols?
      return false if empty?
      return false if alphanumeric?
      (to_str.chars - ('!'..'~').to_a).empty?
    end

    # Returns new grid by rotating self so that the element at cnt in self is
    # the first element of the new grid. If cnt is negative then it rotates in
    # the opposite direction.
    #
    def rotate(r: 0, c: 0)
      self.class.new @arr.rotate(r).map{|row| row.rotate(c)}
    end

    def to_a
      @arr
    end

    def to_str
      @arr.join
    end

    def to_vstr
      transpose.to_str
    end

    def to_s
      @arr.map{|x| x.join(" ")}.join("\n")
    end

    def print(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      puts(col_size > 40 || options[:concise] ? to_s.gsub(" ", '') : to_s)
      return self
    end

    def inspect
      chars = to_str[0..36] + (length > 36 ? "...." : "")
      chars = "" if length == 0
      "#{self.class}[rows=#{row_size},cols=#{col_size},length=#{length}]{\"#{chars}\"}"
    end


    def raise_if_invalid_array!
      valid   = @arr.is_a?(Array)
      valid &&= @arr.reject{|r| r.is_a?(Array)}.empty?
      valid &&= @arr.join.length == @arr.size * (@arr[0].size rescue 0)
      raise Passcard::Error, "A Grid requires 2D array" unless valid
    end
  end
end
