module Passe
  class OptionParser
    def initialize(options={})
      @config, @opts = {}, options

      @defaults = {
        symbols: true, concise: false, size: "50x50", style: :default,
        numrows: true, headers: Passe::HEADERS,
        algorithms: Passe::ALGORITHMS
      }
    end

    def parse!
      @config = read_config || {}
      @config = @defaults.merge(@config).merge(@opts)

      set_numrows
      set_size_of_grid
      set_row_and_col_headers
      set_charspace
      set_algorithms

      check_row_length!
      check_col_length!

      @config.merge(size: @size, rows: @rows, cols: @cols,
                    numrows: @numrows, charspace: @charspace,
                    max_ord: (@rows + @cols).map(&:ord).max,
                    algorithms: @algorithms)
    end

    protected

    def read_config
      path = @opts.fetch(:config, Passe.root.join("defaults.yml"))
      raise if !path.readable?

      config = YAML.load_file(path.to_s)

      style  = @defaults.delete(:style)
      style  = @opts.delete(:style).to_sym if @opts[:style]
      config = config[style.to_s] || config[style.to_sym]
      Hash[config.map{|k,v| [k.to_s.to_sym, v]}]
    end

    def set_numrows
      @numrows = @config[:numrows].to_i if @config[:numrows].respond_to?(:to_i)
      @numrows ||= @config[:numrows] ? Passe::NUM_ROWS : 0
    end

    def set_size_of_grid
      @size    = @config[:size].scan(/(\d+)[^\d+](\d+)/).flatten.map(&:to_i)
      @size[1] = @size[1] * 2 if @config[:concise]
    end

    def set_row_and_col_headers
      @rows, @cols = [:rows, :cols].map.with_index do |header, idx|
        header = @config[header] || @config[:headers]
        header.gsub(/\s+/, '').chars.uniq.sort.take(@size[idx])
      end
    end

    def set_charspace
      @charspace = @config[:charspace_alnum] || CS_ALPHANUM
      @charspace = (@config[:charspace] || CS_ALNUMSYM) if @config[:symbols]
    end

    def set_algorithms
      @algorithms = @config[:algorithms].join(",")
      @algorithms = @algorithms.split(/(,|\s+)/) if @algorithms.is_a?(String)
      @algorithms = @algorithms.map(&:upcase) & ALGORITHMS
    end

    def check_row_length!
      return if @rows.length >= @size[0]
      message = "Given row-size of #{@size[0]} is greater than size of row headers!"
      raise Passe::Error, message
    end

    def check_col_length!
      return if @cols.length >= @size[0]
      message = "Given column-size of #{@size[0]} is greater than size of column headers!"
      raise Passe::Error, message
    end
  end
end
