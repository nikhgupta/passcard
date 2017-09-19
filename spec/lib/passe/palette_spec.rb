# Tests for this class are minimal at the moment, as this class is just a visual
# glue and maybe removed in the future from Passe.
#
RSpec.describe Passe::Palette do
  let(:subject){ described_class.new(:passe, "n" => 5) }

  it "raises error when the palette type can not be found" do
    expect { described_class.new(:unknown_type) }.to raise_error Passe::Error
    expect { described_class.new(:passe) }.not_to raise_error
  end

  it "uses `passe` as the default palette type" do
    expect(described_class.new.type).to eq :passe
  end

  it "allows easy access to the generated colors" do
    expect(subject.colors.count).to eq 5
  end

  it "allows changing palette type and generates new colors" do
    colors = subject.colors
    subject.type = :martin_ankerl
    expect(subject.colors.count).to eq 5
    expect(subject.colors).not_to eq colors
  end

  # FIXME: can be improved
  it "provides text color for each of the color, that is most readable" do
    expect(subject).to receive(:readable_text_color_for).exactly(5).times.and_call_original
    subject.type = :martin_ankerl

    subject.colors.each do |color|
      expect(color[:color]).to represent_a_color
      expect(color[:text_color]).to represent_white.or represent_black
    end
  end

  it "allows setting options for the palette and generates new colors" do
    colors = subject.colors
    subject.options = subject.options.merge("smax" => 0.8)
    expect(subject.colors).not_to eq colors
    expect(subject.colors.count).to eq 5
  end

  it "allows specifying the number of colors to be generated in options" do
    expect(subject.colors.count).to eq 5

    subject.options = { "n" => 0 }
    expect(subject.colors).to be_empty

    subject.options = { "n" => 10 }
    expect(subject.colors.count).to eq 10

    subject.options = { "n" => -10 }
    expect(subject.colors).to be_empty
  end

  it "provides a list of available palette types" do
    expect(subject.list_types).to include(:krazydad, :gradient, :passe, :martin_ankerl)
  end

  # FIXME: not the correct way to test this
  it "generates different colors for each palette type" do
    palettes = [:passe, :gradient, :martin_ankerl, :krazydad]
    colors = palettes.map do |palette|
      subject.type = palette
      subject.colors.map{|color| color[:color]}
    end

    expect(colors.uniq).to eq colors
  end
end
