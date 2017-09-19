require 'nokogiri'
require 'passe/outputter/html_outputter'

RSpec.describe Passe::HtmlOutputter do
  let(:generator){ Passe::Generator.new("secret-word") }
  let(:reader)   { Passe::Reader.new("secret-word", generator.run)}
  let(:subject)  { described_class.new(reader) }

  def html_doc(options = {})
    output = reader.to_html(options)
    Nokogiri::HTML(output)
  end

  def text_for(html, selector)
    html.search("html #{selector}").text.strip
  end

  def span_count(html, selector=nil)
    html.search(".passe-grid #{selector} span").count
  end

  def span_content(html, selector=nil)
    html.search(".passe-grid #{selector} span").map(&:text).join
  end

  def body_style(html)
    html.search("body").attr("style").text.strip
  end

  it "is a subclass of Passe::Outputter" do
    expect(described_class.superclass).to eq Passe::Outputter
  end

  it "registers #to_html method to Passe::Reader" do
    expect(Passe.outputters[:to_html]).to eq [described_class, :to_html]

    double = double()
    expect(described_class).to receive(:new).and_return(double)
    expect(double).to receive(:to_html).and_return("")
    expect(reader.grid).not_to receive(:to_str)

    reader.to_html
  end

  describe "#to_html" do
    it "converts grid to HtML string" do
      html = html_doc()
      expect(span_count(html)).to eq 6400
      expect(text_for(html, "head title")).to eq "Passe Grid"

      regex = /span\s+\{.*display:\s*inline-block/mi
      expect(text_for(html, "head style")).to match(regex)

      expect(body_style(html)).not_to match(/background:\s*linear-gradient/)
      expect(span_content(html)).to eq reader.to_str
    end

    it "fetches a particular style of subgrid" do
      html = html_doc(type: :card)
      expect(span_count(html)).to eq 200
    end

    it "adds headers to the grid output if required" do
      html = html_doc(type: :card, header: true)
      expect(span_count(html)).to eq 200 + (10+20)
      # column headers
      expect(span_count(html, ".col-header")).to eq 20
      expect(span_content(html, ".col-header")).to eq ('A'..'T').to_a.join

      # row headers
      expect(span_count(html, ".row-header")).to eq 10
      expect(span_content(html, ".row-header")).to eq ('A'..'J').to_a.join
    end

    # FIXME: Brittle test?
    it "adds colors to the grid output if required" do
      html = html_doc(color: :gradient)
      expect(body_style(html)).to match(/background:\s*linear-gradient/)

      regex = /color:\s*rgb\(.*?\);\s*background:\s*rgb\(.*?\)/
      html.search(".row").each_with_index do |row, idx|
        style = row.search(".row-content").attr("style").text
        expect(style).to match(regex)
        expect(row.search("span").text).to eq(reader.grid[idx].to_str)
      end
    end
  end
end
