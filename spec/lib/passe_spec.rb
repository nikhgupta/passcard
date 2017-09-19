RSpec.describe Passe do
  it "has a version number" do
    expect(Passe::VERSION).not_to be nil
  end

  it "has a default charset" do
    expect(Passe::CHARSET).not_to be_empty
    expect(Passe::CHARSET).to match(/\A[!-~]+\z/)
  end

  it "has sizes for default grid and subgrids" do
    expect(Passe::GRID_SIZE.count).to eq 2
    expect(Passe::ALPHA_GRID.count).to eq 2
    expect(Passe::NUMERIC_GRID.count).to eq 2

    expect(Passe::ALPHA_GRID[0]+Passe::NUMERIC_GRID[0]).to be<Passe::GRID_SIZE[0]
    expect(Passe::ALPHA_GRID[1]+Passe::NUMERIC_GRID[1]).to be<Passe::GRID_SIZE[1]
  end

  it "defines path to the root directory" do
    expect(Passe.root).to be_a(Pathname)
    expect(Passe.root.to_s.strip).not_to be_empty
  end

  context "reg. outputters" do
    it "allows adding an Outputter class to list of outputters" do
      Passe.register_outputter('to_mp3', "MP3Outputter", 'some_method')
      expect(Passe.outputters).to have_key(:to_mp3)
      expect(Passe.outputters[:to_mp3]).to eq ["MP3Outputter", :some_method]
    end

    it "provides quick access to outputter class for a given format" do
      MP3Outputter = Class.new

      Passe.register_outputter('to_mp3', "MP3Outputter", 'some_method')
      expect(Passe.outputter_class_for('to_mp3')).to eq MP3Outputter
    end

    it "allows removing a registered Outputter" do
      Passe.register_outputter('to_mp3', "MP3Outputter", 'some_method')
      expect(Passe.outputters).to have_key(:to_mp3)
      Passe.unregister_outputter('to_mp3')
      expect(Passe.outputters).not_to have_key(:to_mp3)
      Passe.unregister_outputter('to_unregistered')
      expect(Passe.outputters).not_to have_key(:to_unregistered)
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

  context "Create/Read Passe key files" do
    it "delegates creation of Passe key file to Generator" do
      args = double('args')
      expect(Passe::Generator).to receive(:create_key_file).with(*args)
      Passe.create!(*args)
    end
    it "delegates reading of Passe key file to Reader" do
      args = double('args')
      expect(Passe::Reader).to receive(:read_key_file).with(*args)
      Passe.read!(*args)
    end
  end
end
