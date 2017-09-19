module RSpec::Matchers
  class BeAPasseGrid
    include RSpec::Matchers

    def with_size(*args)
      @row, @col = args.length > 1 ? args : args[0]
      self
    end

    def numeric
      @numeric = true
      self
    end

    def alphanumeric
      @alphanumeric = true
      self
    end

    def with_symbols
      @symbols = true
      self
    end

    def matches?(obj)
      @obj = obj
      return false unless obj.is_a?(Passe::Grid)
      return false if obj.size != [@row, @col]  if @row && @col
      return false if obj.length != @row * @col if @row && @col
      return false if @numeric && !obj.numeric?
      return false if @alphanumeric && !obj.alphanumeric?
      return false if @symbols && !obj.has_symbols?
      return true
    end

    def failure_message
      message  = "Expected:\n#{@obj} -- to be a Passe grid"
      message += " with size #{@row}x#{@col}" if @row && @col
      if @obj.is_a?(Passe::Grid) && @row
        message += ", but found size to be: #{@obj.row_size}x#{@obj.col_size}"
      end
      message
    end
  end

  def be_a_passe_grid
    BeAPasseGrid.new
  end
end

