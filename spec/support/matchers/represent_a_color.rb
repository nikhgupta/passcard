module RSpec::Matchers
  class RepresentAColor
    include ::RSpec::Matchers
    include ::RSpec::Matchers::Composable

    def initialize(*color)
      @color = color
      super()
    end

    def matches?(arr)
      return false unless arr.is_a?(Array) && arr.count == 3
      return arr == @color if @color && @color.any?
      arr.reject{ |a| a >= 0 && a < 256 }.empty?
    end
  end

  def represent_a_color
    RepresentAColor.new
  end

  def represent_black
    RepresentAColor.new(0, 0, 0)
  end

  def represent_white
    RepresentAColor.new(255, 255, 255)
  end
end


