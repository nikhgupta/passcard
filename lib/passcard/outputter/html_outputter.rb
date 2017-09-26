module Passcard
  class HtmlOutputter < Outputter
    register :to_html

    def to_html(options = {})
      html = ""
      get_grid(options)
      use_palette options[:color]

      html += get_col_headers if options[:header]

      grid.row_size.times.map do |i|
        html += "<div class='row'>"
        html += get_row_header(i) if options[:header]
        html += get_row(i, options[:color])
        html += "</div>"
      end

      data = data_in(__FILE__).gsub('{{GRID}}', html)
      data = data.gsub('{{BACKGROUND}}', get_background) if options[:color]
      data
    end

    private

    def get_background
      bg1= "rgb(#{@palette.colors[0][:color].join(",")})"
      bg2= "rgb(#{@palette.colors[-1][:color].join(",")})"
      "background:linear-gradient(#{bg2},#{bg1})"
    end

    def get_style(idx, colors = true)
      return unless colors
      color = "rgb(#{@palette.colors[idx][:color].join(",")})"
      textc = "rgb(#{@palette.colors[idx][:text_color].join(",")})"
      return "style='color: #{textc}; background: #{color}'"
    end

    def get_row(idx, colors=true)
      <<-HTML
        <div class='row-content' #{get_style(idx, colors)}>
          <span>#{grid[idx].to_a.join("</span><span>")}</span>
        </div>
      HTML
    end

    def get_row_header(i)
      <<-HTML
      <div class='row-header'>
        <span>#{row_headers[i]}</span>
      </div>
      HTML
    end

    def get_col_headers
      <<-HTML
      <div class='col-header'>
        <span>#{col_headers.join("</span><span>")}</span>
      </div>
      HTML
    end
  end
end

__END__

<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title> Passcard Grid </title>

    <style type="text/css">
      * {
        margin: 0;
        padding: 0;
        font-family: monospace;
      }
      html, body {
        height: 100%;
        width: 100%;
        color: white;
        background-color: #666;
      }
      .passcard-grid {
        width: 800px;
        text-align: right;
      }
      span {
        font-size: 17px;
        padding: 4px;
        height: 21px;
        width: 21px;
        text-align: center;
        vertical-align: middle;
        display: inline-block;
      }
      .row {
        clear: both;
        width: 800px;
        text-align: right;
      }
      .row-header {
        color: white;
        background-color: #666;
      }
      .row-header span {
        float: left;
      }
      .col-header {
        padding-left: 28px
      }
      .col-header span, .row-header span {
        font-weight: bold;
        color: black;
      }
      .row-content {
        margin-left: 40px;
      }
    </style>
  </head>
  <body style='{{BACKGROUND}}'>
    <div class="passcard-grid">
      {{GRID}}
    </div>
  </body>
</html>
