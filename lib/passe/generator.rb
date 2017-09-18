module Passe
  class Generator
    def initialize(seed, options = {})
      @seed = @input = seed
      @opts = Passe::OptionParser.new(options).parse!
    end

    def reset!
      @seed = @input
    end

    def hash
      index = @seed[0].to_i(16) % @opts[:algorithms].length
      @seed = Digest.const_get(@opts[:algorithms][index]).hexdigest(@seed)
    rescue NameError
      @seed = Digest::SHA256.hexdigest(@seed)
    end

    def shuffle(arr)
      arr = arr.chars if arr.is_a?(String)
      base = 16 + hash.gsub(/[^0-9]/, '').to_i % 21
      arr.shuffle(:random => Random.new(hash.to_i(base)))
    end

    def generate_space(chars)
      space  = shuffle(chars)
      space += shuffle(space) while space.length <= @opts[:max_ord]
      space
    end

    def run
      reset!
      charspace    = self.generate_space(@opts[:charspace])
      numspace     = self.generate_space((0..9).to_a)
      total_rows   = @opts[:rows].length
      numeric_rows = (total_rows * (@opts[:numrows] / 100.0)).to_i

      @opts[:rows].map.with_index do |r, idx|
        @opts[:cols].map do |c|
          space = idx < total_rows - numeric_rows ? charspace : numspace
          shuffle(space)[(r.ord + c.ord) % space.length]
        end
      end
    end

    def to_s
      output = self.run
      @opts[:concise] ? to_concise_str(output) : to_expanded_str(output)
    end

    private

    def to_expanded_str(output)
      str  = "    " + @opts[:cols].join(" ") + "\n"
      str += "    " + "- " * @opts[:cols].length + "\n"

      @opts[:rows].length.times.map do |i|
        str += @opts[:rows][i] + " | " + output[i].join(" ") + "\n"
      end

      str
    end

    def to_concise_str(output)
      str  = "  " + @opts[:cols].join("") + "\n"
      str += "  " + "-" * @opts[:cols].length + "\n"

      @opts[:rows].length.times.map do |i|
        str += @opts[:rows][i] + "|" + output[i].join + "\n"
      end

      str
    end
  end
end
