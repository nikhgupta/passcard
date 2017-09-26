module Passcard
  class Palette
    extend Forwardable
    GOLDEN_RATIO = (1 + Math.sqrt(5))/2

    attr_reader :type, :colors, :options
    def_delegators :@colors, :count, :size, :take, :first, :last, :[]

    def initialize(type = :passcard, options = {})
      self.type    = type
      self.options = options
    end

    def type=(type)
      @type = type.to_s.strip.empty? ? :passcard : type.to_sym

      if !respond_to?("generate_colors_#{@type}", true)
        raise Passcard::Error, "No such color generator: #{@type}"
      end

      update_colors
    end

    def options=(options = {})
      @options = options
      @options["n"] ||= (@options["size"][0] rescue 0)
      update_colors
    end

    def update_colors
      return unless type && options
      @colors = send("generate_colors_#{type}", options).map do |rgb|
        { color: rgb, text_color: readable_text_color_for(rgb) }
      end
    end

    def list_types
      self.methods.map do |method|
        method.to_s.gsub!(/^generate_colors_/, '')
      end.compact.map(&:to_sym)
    end

    protected

    def generate_colors_martin_ankerl(options = {})
      h = rand
      s = options.fetch('s', 0.33)
      v = options.fetch('v', 0.93)

      options['n'].times.map do
        h = (h + 1/GOLDEN_RATIO) % 1
        hsv_to_rgb(h * 360, s, v)
      end
    end

    def generate_colors_krazydad(options = {})
      width  = options.fetch('width',  55)
      center = options.fetch('center', 200)
      phase  = options.fetch('phase',  rand * Math::PI * 2.0)
      freq   = Math::PI / options['n'] * 2.0

      options['n'].times.map do |i|
        red   = Math.sin(freq * i + 0 + phase) * width + center
        green = Math.sin(freq * i + 2 + phase) * width + center
        blue  = Math.sin(freq * i + 4 + phase) * width + center
        [red.round(0), green.round(0), blue.round(0)]
      end
    end

    def generate_colors_gradient(options = {})
      s = rand
      v = options.fetch("v", 0.93)
      from, to = generate_colors_martin_ankerl("s" => s, "v" => v, "n" => 2)

      options['n'].times.map do |i|
        m = i/options['n'].to_f
        3.times.map{ |j| (from[j]*m + to[j] * (1-m)).round(0) }
      end
    end

    def generate_colors_passcard(options = {})
      h = (360 * rand).round(2)
      n = options['n']
      smax = options.fetch('smax', 0.4)
      n = n.times.map{|i| (1+i)/n.to_f * smax * 1.0}
      n.flatten.map{|s| hsl_to_rgb(h, s, 1 - s)}
    end

    private

    # For more info on conversions, read:
    # https://en.wikipedia.org/wiki/HSL_and_HSV
    #
    # Hue is specified in range: 0 <= hue < 360
    #
    def hue_to_rgb(h, c, x, m)
      y = [c, 0, x] if h < 360
      y = [x, 0, c] if h < 300
      y = [0, x, c] if h < 240
      y = [0, c, x] if h < 180
      y = [x, c, 0] if h < 120
      y = [c, x, 0] if h < 60
      y.map{ |a| ((a + m) * 255).round(0) }
    end
    def hsv_to_rgb(h, s, v)
      c = v * s
      x = c * (1 - ((h / 60.0) % 2 - 1).abs)
      m = v - c
      hue_to_rgb(h, c, x, m)
    end
    def hsl_to_rgb(h, s, l)
      c = (1 - (2 * l - 1).abs) * s
      x = c * (1 - ((h / 60.0) % 2 - 1).abs)
      m = l - c / 2.0
      hue_to_rgb(h, c, x, m)
    end

    # Read: https://www.w3.org/TR/WCAG20/#relativeluminancedef
    def luminosity_for(rgb)
      conv = rgb.map do |c|
        c/255.0 <= 0.03928 ? c/255.0/12.92 : ((c/255.0+0.055)/1.055)**2.4
      end
      conv[0] * 0.2126 + conv[1] * 0.7152 + conv[2] * 0.0722
    end

    # Read: https://www.w3.org/TR/WCAG20/#contrast-ratiodef
    def readable_text_color_for(rgb, dark = nil, light = nil)
      dark  ||= [  0,  0,  0]
      light ||= [255,255,255]
      lc, ld, ll = [rgb, dark, light].map{|color| luminosity_for(color)}
      (lc + 0.05) / (ld + 0.05) > (ll + 0.05) / (lc + 0.05) ? dark : light
    end
  end
end
