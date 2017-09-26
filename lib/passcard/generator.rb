module Passcard
  class Generator
    attr_accessor :options

    def self.create_key_file(key, path, options = {})
      passcard = self.new(key, options)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, "w") do |f|
        f.print "-" * 20 + " BEGIN PASSCARD KEY " + "-" * 23 + "\n"
        f.print passcard.run
        f.print "-" * 20 + " END PASSCARD KEY " + "-" * 25
      end
    end

    def initialize(secret = nil, options = {})
      @secret = secret.to_s.strip.sha512

      @options = { "charset" => Passcard::CHARSET }.merge(options)
      @options.merge!("size" => Passcard::GRID_SIZE,
        "numeric" => Passcard::NUMERIC_GRID, "alpha" => Passcard::ALPHA_GRID)
    end

    def run
      return encrypt_options! if options['grid']

      charspace  = options['charset'].chars.shuffle
      numspace   = options['charset'].gsub(/[^0-9]+/, '').chars.shuffle
      alphaspace = options['charset'].gsub(/[^a-z0-9]+/i, '').chars.shuffle

      numspace   = (0..9).to_a.shuffle if numspace.empty?
      alphaspace = (('a'..'z').to_a+('A'..'Z').to_a).shuffle if alphaspace.empty?

      @options['grid'] = @options['size'][0].times.map do |r|
        @options['size'][1].times.map do |c|
          get_character(r, c, alphaspace, numspace, charspace)
        end
      end.join

      encrypt_options!
    end

    def get_character(r, c, alphaspace, numspace, charspace)
      space = alphanumeric?(r,c) ? alphaspace : charspace
      space = numeric?(r,c) ? numspace : space
      space.shuffle[(r + c) % space.length]
    end

    def numeric?(r, c)
      return false if r >= @options["numeric"][0]
      return false if c >= @options["numeric"][1]
      return true
    end

    def alphanumeric?(r, c)
      return false if r < @options["size"][0] - @options["alpha"][0]
      return false if c < @options["size"][1] - @options["alpha"][1]
      return true
    end

    protected

    def encrypt_options!
      Passcard.encrypt!(@secret, @options.to_h)
    end
  end
end
