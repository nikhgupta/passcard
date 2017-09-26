RSpec.describe Passcard do
  it "has a version number" do
    expect(Passcard::VERSION).not_to be nil
  end

  it "has a default charset" do
    expect(Passcard::CHARSET).not_to be_empty
    expect(Passcard::CHARSET).to match(/\A[!-~]+\z/)
  end

  it "has sizes for default grid and subgrids" do
    expect(Passcard::GRID_SIZE.count).to eq 2
    expect(Passcard::ALPHA_GRID.count).to eq 2
    expect(Passcard::NUMERIC_GRID.count).to eq 2

    expect(Passcard::ALPHA_GRID[0]+Passcard::NUMERIC_GRID[0]).to be<Passcard::GRID_SIZE[0]
    expect(Passcard::ALPHA_GRID[1]+Passcard::NUMERIC_GRID[1]).to be<Passcard::GRID_SIZE[1]
  end

  it "defines path to the root directory" do
    expect(Passcard.root).to be_a(Pathname)
    expect(Passcard.root.to_s.strip).not_to be_empty
  end

  context "reg. outputters" do
    it "allows adding an Outputter class to list of outputters" do
      Passcard.register_outputter('to_mp3', "MP3Outputter", 'some_method')
      expect(Passcard.outputters).to have_key(:to_mp3)
      expect(Passcard.outputters[:to_mp3]).to eq ["MP3Outputter", :some_method]
    end

    it "provides quick access to outputter class for a given format" do
      MP3Outputter = Class.new

      Passcard.register_outputter('to_mp3', "MP3Outputter", 'some_method')
      expect(Passcard.outputter_class_for('to_mp3')).to eq MP3Outputter
    end

    it "allows removing a registered Outputter" do
      Passcard.register_outputter('to_mp3', "MP3Outputter", 'some_method')
      expect(Passcard.outputters).to have_key(:to_mp3)
      Passcard.unregister_outputter('to_mp3')
      expect(Passcard.outputters).not_to have_key(:to_mp3)
      Passcard.unregister_outputter('to_unregistered')
      expect(Passcard.outputters).not_to have_key(:to_unregistered)
    end
  end

  context "Encryption/Decryption" do
    it "can encrypt/decrypt objects with JSON representation" do
      key, enc_str, dec_obj = "secretkey", nil, nil
      object  = { "a" => [1, 2, 3], "b" => true, c: "somestring" }
      expect {
        enc_str = described_class.encrypt!(key, object)
      }.not_to raise_error

      expect {
        dec_obj = described_class.decrypt!(key, enc_str)
        object["c"] = object.delete(:c)
        expect(dec_obj).to eq object
      }.not_to raise_error

      expect {
        dec_obj = described_class.decrypt!("otherkey", enc_str)
      }.to raise_error(OpenSSL::Cipher::CipherError, "bad decrypt")
    end
  end

  context "Create/Read Passcard key files" do
    it "delegates creation of Passcard key file to Generator" do
      args = double('args')
      expect(Passcard::Generator).to receive(:create_key_file).with(*args)
      Passcard.create!(*args)
    end
    it "delegates reading of Passcard key file to Reader" do
      args = double('args')
      expect(Passcard::Reader).to receive(:read_key_file).with(*args)
      Passcard.read!(*args)
    end
  end
end
