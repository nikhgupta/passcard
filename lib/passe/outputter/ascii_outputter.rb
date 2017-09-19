module Passe
  class AsciiOutputter < Outputter
    register :to_ascii, to_s: :to_ascii

    def to_ascii(options = {})
      str = ""
      get_grid(options)
      use_palette options[:color]

      str += get_col_headers if options[:header]

      grid.row_size.times.map do |i|
        str += row_headers[i].to_s + " | " if options[:header]
        str += get_row(i, options[:color])
        str += "\n"
      end

      str
    end

    private

    def get_col_headers
      "    #{col_headers.join(" ")}\n    #{"- "*col_headers.length}\n"
    end

    def get_row(idx, colors=true)
      row  = grid[idx].to_s
      return row unless colors

      str  = "\x1b[48;2;#{@palette.colors[idx][:color].join(";")}m"
      str += "\x1b[38;2;#{@palette.colors[idx][:text_color].join(";")}m"

      "#{str}#{row}\x1b[0m"
    end
  end
end
