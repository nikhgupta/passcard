RSpec.describe Passcard::Outputter do
  let(:generator){ Passcard::Generator.new("secret-word") }
  let(:reader)   { Passcard::Reader.new("secret-word", generator.run)}
  let(:subject)  { described_class.new(reader) }

  class DummyOutputter < Passcard::Outputter
    ROW_HEADERS = "☾ ✈ ☎ ☀ ☁ ☂ ☃ ★ ⌘ ♞ "
    COLUMN_HEADERS = "♞ ⌘ ★ ☃ ☂ ☁ ☀ ☎ ✈ ☾ "
  end

  it "has access to Passcard::Generator instance" do
    expect(subject.reader).to eq reader
  end

  it "allows registering methods in subclasses as outputters" do
    klass = Class.new(described_class){ register 'to_a' }
    expect(Passcard.outputters).to have_key(:to_a)
    expect(Passcard.outputters[:to_a]).to eq [klass, :to_a]

    klass = Class.new(described_class){ register to_a: :create_a }
    expect(Passcard.outputters).to have_key(:to_a)
    expect(Passcard.outputters[:to_a]).to eq [klass, :create_a]

    klass = Class.new(described_class){ register 'to_c', to_d: :create_d }
    expect(Passcard.outputters).to have_key(:to_c)
    expect(Passcard.outputters).to have_key(:to_d)
    expect(Passcard.outputters[:to_c]).to eq [klass, :to_c]
    expect(Passcard.outputters[:to_d]).to eq [klass, :create_d]

    expect {
      klass = Class.new(described_class){ register }
    }.to raise_error(Passcard::Error)
    expect {
      klass = Class.new(described_class){ register({}) }
    }.to raise_error(Passcard::Error)
  end

  describe "#get_grid" do
    it "sets default palette for the outputter" do
      expect(subject.palette.count).to eq 0

      subject.get_grid
      expect(subject.palette.count).to eq 80

      subject.get_grid type: :alphanum
      expect(subject.palette.count).to eq 26
    end

    it "resets the grid on each use as per given options" do
      subject.get_grid type: :pincard
      expect(subject.grid).to be_a_passcard_grid.with_size(10, 20)

      subject.get_grid type: :alphanum
      expect(subject.grid).to be_a_passcard_grid.with_size(26, 26)
    end

    it "allows fetching a random subgrid" do
      subject.get_grid type: :random
      expect(subject.grid).to be_a_passcard_grid.with_size(20, 30)

      grid = subject.grid
      subject.get_grid type: :random
      expect(subject.grid).to be_a_passcard_grid.with_size(20, 30)
      expect(subject.grid).not_to eq grid
    end

    it "allows fetching two distinct numbers only Pincard subgrids" do
      subject.get_grid type: :pincard
      expect(subject.grid).to be_a_passcard_grid.with_size(10, 20).numeric

      grid = subject.grid
      expect(subject.get_grid(type: :pincard)).to eq grid

      alternate = subject.get_grid(type: :pincard_alt)
      expect(subject.grid).not_to eq grid
      expect(subject.grid).to eq(alternate).and be_a_passcard_grid
        .with_size(10, 20).numeric
    end

    it "allows fetching two distinct alphanumeric subgrids" do
      subject.get_grid type: :alphanum
      expect(subject.grid).to be_a_passcard_grid.with_size(26, 26).alphanumeric

      grid = subject.grid
      expect(subject.get_grid(type: :alphanum)).to eq grid

      alternate = subject.get_grid(type: :alphanum_alt)
      expect(subject.grid).not_to eq grid
      expect(subject.grid).to eq(alternate).and be_a_passcard_grid
        .with_size(26, 26).alphanumeric
    end

    it "allows fetching a square subgrid of alphabets, numbers and symbols" do
      subject.get_grid type: :square
      expect(subject.grid).to be_a_passcard_grid.with_size(20, 20).with_symbols

      grid = subject.grid
      expect(subject.get_grid(type: :square)).to eq grid
    end

    it "allows fetching a large card size subgrid of alphabets, numbers and symbols" do
      subject.get_grid type: :card_large
      expect(subject.grid).to be_a_passcard_grid.with_size(15, 30).with_symbols

      grid = subject.grid
      expect(subject.get_grid(type: :card_large)).to eq grid
    end

    it "allows fetching card size subgrid of alphabets, numbers and symbols" do
      subject.get_grid type: :card
      expect(subject.grid).to be_a_passcard_grid.with_size(10, 20).with_symbols
    end

    it "defaults to returning the complete grid" do
      expect(subject.get_grid).to eq(reader.grid).and be_a_passcard_grid.with_size(80, 80)
    end
  end

  it "does not generate the grid on instantiation" do
    expect(subject.grid).to be_nil
    subject.get_grid
    expect(subject.grid).to be_a_passcard_grid
  end

  describe "#data_in" do
    it "reads the DATA stored in a file at the __END__" do
      content = "a\nbc\n__END__  \n  this is the data\n that we need!\n  "
      allow(File).to receive(:read).and_return content
      expect(subject.data_in("somefile")).to eq "this is the data\n that we need!"
    end

    it "returns an empty string when no such data can be found" do
      allow(File).to receive(:read).and_return "a\nbc\nnothing!"
      expect(subject.data_in("somefile")).to be_empty
    end
  end

  describe "#row_headers" do
    it "specifies default row headers for outputters" do
      subject.get_grid
      expect(subject.grid.row_size).to eq 80
      expect(subject.row_headers.size).to eq 80
    end
    it "allows specifying a different row header within the outputter class" do
      dummy = DummyOutputter.new(reader)
      dummy.get_grid
      expect(dummy.row_headers).to eq %w[ ☾ ✈ ☎ ☀ ☁ ☂ ☃ ★ ⌘ ♞ ]
    end
  end

  describe "#col_headers" do
    it "specifies default column headers for outputters" do
      subject.get_grid
      expect(subject.grid.col_size).to eq 80
      expect(subject.col_headers.size).to eq 80
    end
    it "allows specifying a different column header within the outputter class" do
      dummy = DummyOutputter.new(reader)
      dummy.get_grid
      expect(dummy.col_headers).to eq %w[ ☾ ✈ ☎ ☀ ☁ ☂ ☃ ★ ⌘ ♞ ].reverse
    end
  end

  it "has access to Passcard::Palette when required" do
    expect(subject.palette.count).to eq 0
    subject.get_grid
    expect(subject.palette).to be_a(Passcard::Palette)
    expect(subject.palette.count).to eq subject.grid.row_size
  end

  it "allows using a particular palette, if required" do
    subject.get_grid
    subject.use_palette :gradient, "v" => 0.6
    expect(subject.palette.type).to  eq :gradient
    expect(subject.palette.count).to eq subject.grid.row_size
    expect(subject.palette.options).to include("v" => 0.6)
  end


end
