RSpec.describe 'Passcard::CLI.generate', :slow, type: :aruba do
  context "with default options" do
    it "should create a PASSCARD key in current directory" do
      generate_passcard "-s", "secret-word"
      expect(command).to be_successfully_executed
      expect("passcard.key").to be_an_existing_file
      expect(stdout).to include "Created Passcard key in: ./passcard.key"
      expect("passcard.key").to be_a_passcard_key.with_secret("secret-word")
    end

    it "should not overwrite existing file" do
      write_file "passcard.test", "a"
      generate_passcard "-i", "passcard.test", key: "secret-word"
      expect(command).not_to be_successfully_executed
      expect("passcard.test").not_to be_a_passcard_key.with_secret("secret-word")
        .has_error(/data must not be empty/)

      write_file "passcard.test", "a\nb\nc\nd"
      generate_passcard "-i", "passcard.test", key: "secret-word"
      expect(command).not_to be_successfully_executed
      expect("passcard.test").not_to be_a_passcard_key.with_secret("secret-word")
        .has_error(OpenSSL::Cipher::CipherError, "wrong final block length")
    end
  end

  context "with custom options" do
    it "should overwrite existing file when forced" do
      write_file "passcard.test", "a"
      generate_passcard "-i", "passcard.test", "-f", key: "secret-word"
      expect(command).to be_successfully_executed
      expect(stdout).to include "Overwriting file at: passcard.test"
      expect("passcard.test").to be_a_passcard_key.with_secret("secret-word")
    end

    it "should use generate Passcard key at specified path" do
      generate_passcard "-i", "dir/passcard.test", key: "secret-word"
      expect(command).to be_successfully_executed
      expect("dir/passcard.test").to be_a_passcard_key.with_secret("secret-word")
    end

    it "allows specifying secret key via command options" do
      generate_passcard "--secret-key whatever"
      expect(command).to be_successfully_executed
      expect("passcard.key").to be_a_passcard_key.with_secret("whatever")
    end

    it "allows using a specific character set" do
      generate_passcard "--charset 0123456789abcdef", key: "secret-word"
      expect(command).to be_successfully_executed
      expect("passcard.key").to be_a_passcard_key.with_secret("secret-word").
        with_charset_matching(/[a-f0-9]+/)
    end
  end

  context "behaviour of generated grid" do
    it "should not be decryptable with wrong secret key" do
      generate_passcard key: "secret-word"
      expect(command).to be_successfully_executed
      expect("passcard.key").to be_a_passcard_key.with_secret("secret-word")

      expect {
        expect("passcard.key").to be_a_passcard_key.with_secret("other-word")
      }.to raise_error(OpenSSL::Cipher::CipherError, "bad decrypt")
    end

    it "should generated different grids with the same key on multiple runs" do
      generate_passcard "-i passcard1.key", key: "secret-word"
      expect(command).to be_successfully_executed
      expect("passcard1.key").to be_a_passcard_key.with_secret("secret-word")

      generate_passcard "-i passcard2.key", key: "secret-word"
      expect(command).to be_successfully_executed
      expect("passcard2.key").to be_a_passcard_key.with_secret("secret-word")

      grid1 = Passcard.read!("secret-word", "tmp/aruba/passcard1.key")["grid"]
      grid2 = Passcard.read!("secret-word", "tmp/aruba/passcard2.key")["grid"]

      expect(grid1).not_to eq(grid2)
    end
  end
end
RSpec.describe "Passcard::CLI.view", :slow, type: :aruba do
  let(:secret) { "secret-word" }
  before(:each){ generate_passcard "-i passcard.key -s #{secret}" }

  def try_extracting_grid_str(str)
    regex = /.*?\e\[.*\e\[.*?m(.*?)\e\[0m.*$/mi
    str.lines.map do |l|
      l.gsub(/\s+/, '').gsub!(regex, '\1')
    end.compact.join
  end

  context "with default options" do
    it "should exit unsuccessfully if no Passcard key file was specified" do
      view_passcard file: ""
      expect(command).not_to be_successfully_executed
      expect(stderr).to match(/^ERROR:.*was called with no arguments/)
    end

    it "should show the specified Passcard key" do
      view_passcard key: secret, file: "passcard.key"
      expect(command).to be_successfully_executed

      # type and format: card, ascii
      expect(stdout).not_to match(/<body.*?>/)
      expect(stdout).to include(('A'..'T').to_a.join(" "))
      expect(stdout.length).to be > 260
      expect(try_extracting_grid_str(stdout).length).to eq 200

      # header
      expect(stdout).to match(/A \|.*\nB \|/m)
      expect(stdout).to match(/^\s+(- )+\s*$/)

      # colors
      lines_with_colors = stdout.lines.select do |line|
        line =~ /\e\[.*?m.*\e\[0m/
      end
      expect(lines_with_colors.count).to eq 10
    end
  end

  context "with custom options" do
    it "can be customized to not show headers" do
      view_passcard "--no-header", key: secret, file: "passcard.key"
      expect(command).to be_successfully_executed
      expect(stdout).not_to match(/A \|.*\nB \|/m)
      expect(stdout).not_to match(/^\s+(- )+\s*$/)
    end

    it "can be customized to not show colors" do
      view_passcard "--no-color", key: secret, file: "passcard.key"
      expect(command).to be_successfully_executed

      lines_with_colors = stdout.lines.select do |line|
        line =~ /\e\[.*?m.*\e\[0m/
      end
      expect(lines_with_colors.count).to eq 0
    end

    it "can be customized to show a different subgrid" do
      view_passcard "-t alphanum", key: secret, file: "passcard.key"
      expect(command).to be_successfully_executed
      expect(try_extracting_grid_str(stdout).length).to eq 26**2
    end

    it "can be customized to output using a different format/outputter" do
      view_passcard "--no-header", "-f html", key: secret, file: "passcard.key"
      expect(command).to be_successfully_executed
      expect(stdout).to match(/<body.*?>/)
      expect(stdout.scan(/<span>.<\/span>/).count).to eq 200
      expect(stdout).not_to include(('A'..'T').to_a.join(" "))
    end

    it "secret key can be supplied with CLI arguments itself" do
      view_passcard "-s #{secret}", file: "passcard.key"
      expect(command).to be_successfully_executed
      expect(try_extracting_grid_str(stdout).length).to eq 200
    end
  end
end
