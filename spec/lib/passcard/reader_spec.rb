RSpec.describe Passcard::Reader do
  let(:key) { "secret-word" }
  let(:enc_text) { Passcard::Generator.new(key).run }
  let(:reader){ Passcard::Reader.new(key, enc_text) }

  it "allows easy access to Passcard options that were used to generate" do
    expect(reader.opts['charset']).not_to be_empty
    %w[size numeric alpha].each do |field|
      expect(reader.opts[field]).to be_a(Array)
      expect(reader.opts[field].count).to eq 2
    end
  end

  it "allows easy access to Passcard grid" do
    expect(reader.grid).to be_a(Passcard::Grid)
    expect(reader.grid.size).to eq reader.opts["size"]
  end

  context "extracting sub-grids" do
    it "pre-defined numeric sub-grid" do
      expect(reader.numeric_grid).to be_a(Passcard::Grid)
      expect(reader.numeric_grid.size).to eq reader.opts["numeric"]
    end

    it "allows easy access to alphanumeric sub-grid in the Passcard grid" do
      expect(reader.alpha_grid).to be_a(Passcard::Grid)
      expect(reader.alpha_grid.size).to eq reader.opts["alpha"]
    end

    it "allows fetching a random sub-grid" do
      expect(reader.random_grid).to be_a_passcard_grid.with_size(10, 10)

      expect(reader.random_grid(5, 5)).to be_a_passcard_grid.with_size(5, 5)
      expect(reader.random_grid(100, 100)).to be_a_passcard_grid.with_size(*reader["size"])

      expect(reader.random_grid(0, 0)).to be_a_passcard_grid.with_size(0, 0)
      expect(reader.random_grid(0, 1)).to be_a_passcard_grid.with_size(0, 0)
      expect(reader.random_grid(1, 0)).to be_a_passcard_grid.with_size(0, 0)
      expect(reader.random_grid(1, 1)).to be_a_passcard_grid.with_size(1, 1)
    end

    it "delegates unknown methods" do
      expect(reader.grid).to receive(:print)
      reader.print

      hash = spy("hash")
      allow(reader).to receive(:to_hash).and_return(hash)
      expect(hash).to receive(:has_key?).with("something")
      reader.has_key?("something")

      expect{ reader.unknown_method }.to raise_error(NoMethodError)
    end
  end

  context "reg. outputters" do
    it "delegates method to outputter which register such a method" do
      MP32Outputter = Class.new(Passcard::Outputter) do
        register :to_mp3
      end

      out = spy('mp3_outputter')
      expect(MP32Outputter).to receive(:new).with(reader).and_return(out)
      expect(out).to receive(:to_mp3).with(:a, b: :c)
      reader.to_mp3(:a, b: :c)
    end
  end

  context "#to_s" do
    it "delegates #to_s to the AsciiOutputter" do
      double = double()
      expect_any_instance_of(Passcard::AsciiOutputter).to receive(:to_ascii)
        .and_return(double)
      expect(reader.to_s).to eq double
    end

    it "uses registered outputter for #to_s if available" do
      Class.new(Passcard::Outputter){ register :to_s; def to_s; "a"; end }
      expect(reader.to_s).to eq "a"
    end

    it "fallsback to #to_s for the grid when outputter #to_s is nil" do
      # Passcard.unregister_outputter :to_s
      HELPER = Class.new(Passcard::Outputter){ register :to_s; def to_s; end }
      expect(reader.to_s).to eq reader.grid.to_s
    end
  end
end
