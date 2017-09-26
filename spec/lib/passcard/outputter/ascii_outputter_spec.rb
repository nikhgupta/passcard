RSpec.describe Passcard::AsciiOutputter do
  let(:generator){ Passcard::Generator.new("secret-word") }
  let(:reader)   { Passcard::Reader.new("secret-word", generator.run)}
  let(:subject)  { described_class.new(reader) }

  it "is a subclass of Passcard::Outputter" do
    expect(described_class.superclass).to eq Passcard::Outputter
  end

  it "registers #to_s and #to_ascii methods to Passcard::Reader" do
    expect(Passcard.outputters[:to_s]).to eq [described_class, :to_ascii]
    expect(Passcard.outputters[:to_ascii]).to eq [described_class, :to_ascii]

    double = double()
    expect(described_class).to receive(:new).twice.and_return(double)
    expect(double).to receive(:to_ascii).twice.and_return("")
    expect(reader.grid).not_to receive(:to_str)

    reader.to_s; reader.to_ascii
  end

  describe "#to_s" do
    it "delegates to #to_ascii" do
      double = double()
      expect(described_class).to receive(:new).and_return(double)
      expect(double).to receive(:to_ascii).with(whatever: true)
      reader.to_s(whatever: true)
    end
  end

  describe "#to_ascii" do
    it "converts grid to a printable string for console output" do
      output = reader.to_ascii
      expect(output).to be_a(String)
      expect(output).to eq reader.grid.to_s + "\n"
      expect(output.gsub(/\s+/, '').length).to eq 6400
    end

    it "fetches a particular style of subgrid" do
      output = reader.to_ascii(type: :card)
      expect(output.gsub(/\s+/, '').length).to eq 200
    end

    it "adds headers to the grid output if required" do
      output = reader.to_ascii(type: :card, header: true)
      expect(output.gsub(/\s+/, '').length).to eq 200 + (10+20) * 2
      # column headers
      expect(output.split("\n")[0].strip).to eq ('A'..'T').to_a.join(" ")
      # row headers
      h = output.split("\n").map{|a| a[0]}.join
      expect(h.strip).to eq ('A'..'J').to_a.join
    end

    # FIXME: Brittle test?
    it "adds colors to the grid output if required" do
      regex = /^\e\[48;2;\d+;\d+;\d+m\e\[38;2;\d+;\d+;\d+m.*?\e\[0m$/
      output = reader.to_ascii
      output.lines.each{ |line| expect(line).not_to match regex }

      output = reader.to_ascii(color: :passcard)
      output.lines.each.with_index do |line, idx|
        expect(line).to match regex
        expect(line).to include(reader.grid[idx].to_s)
      end
    end
  end
end
