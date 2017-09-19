RSpec.describe 'Passe::CLI.generate', :slow, type: :aruba do
  context "with default options" do
    it "should create a PASSE key in current directory" do
      generate_passe "-s", "secret-word"
      expect(command).to be_successfully_executed
      expect("passe.key").to be_an_existing_file
      expect(stdout).to include "Created Passe key in: ./passe.key"
      expect("passe.key").to be_a_passe_key.with_secret("secret-word")
    end

    it "should not overwrite existing file" do
      write_file "passe.test", "a"
      generate_passe "-i", "passe.test", key: "secret-word"
      expect(command).not_to be_successfully_executed
      expect("passe.test").not_to be_a_passe_key.with_secret("secret-word")
        .has_error(/data must not be empty/)

      write_file "passe.test", "a\nb\nc\nd"
      generate_passe "-i", "passe.test", key: "secret-word"
      expect(command).not_to be_successfully_executed
      expect("passe.test").not_to be_a_passe_key.with_secret("secret-word")
        .has_error(OpenSSL::Cipher::CipherError, "wrong final block length")
    end
  end

  context "with custom options" do
    it "should overwrite existing file when forced" do
      write_file "passe.test", "a"
      generate_passe "-i", "passe.test", "-f", key: "secret-word"
      expect(command).to be_successfully_executed
      expect(stdout).to include "Overwriting file at: passe.test"
      expect("passe.test").to be_a_passe_key.with_secret("secret-word")
    end

    it "should use generate Passe key at specified path" do
      generate_passe "-i", "dir/passe.test", key: "secret-word"
      expect(command).to be_successfully_executed
      expect("dir/passe.test").to be_a_passe_key.with_secret("secret-word")
    end

    it "allows specifying secret key via command options" do
      generate_passe "--secret-key whatever"
      expect(command).to be_successfully_executed
      expect("passe.key").to be_a_passe_key.with_secret("whatever")
    end

    it "allows using a specific character set" do
      generate_passe "--charset 0123456789abcdef", key: "secret-word"
      expect(command).to be_successfully_executed
      expect("passe.key").to be_a_passe_key.with_secret("secret-word").
        with_charset_matching(/[a-f0-9]+/)
    end
  end

  context "behaviour of generated grid" do
    it "should not be decryptable with wrong secret key" do
      generate_passe key: "secret-word"
      expect(command).to be_successfully_executed
      expect("passe.key").to be_a_passe_key.with_secret("secret-word")

      expect {
        expect("passe.key").to be_a_passe_key.with_secret("other-word")
      }.to raise_error(OpenSSL::Cipher::CipherError, "bad decrypt")
    end

    it "should generated different grids with the same key on multiple runs" do
      generate_passe "-i passe1.key", key: "secret-word"
      expect(command).to be_successfully_executed
      expect("passe1.key").to be_a_passe_key.with_secret("secret-word")

      generate_passe "-i passe2.key", key: "secret-word"
      expect(command).to be_successfully_executed
      expect("passe2.key").to be_a_passe_key.with_secret("secret-word")

      grid1 = Passe.read!("secret-word", "tmp/aruba/passe1.key")["grid"]
      grid2 = Passe.read!("secret-word", "tmp/aruba/passe2.key")["grid"]

      expect(grid1).not_to eq(grid2)
    end
  end
end
RSpec.describe "Passe::CLI.view", :slow, type: :aruba do
  let(:secret) { "secret-word" }
  before(:each){ generate_passe "-i passe.key -s #{secret}" }

  def try_extracting_grid_str(str)
    regex = /.*?\e\[.*\e\[.*?m(.*?)\e\[0m.*$/mi
    str.lines.map do |l|
      l.gsub(/\s+/, '').gsub!(regex, '\1')
    end.compact.join
  end

  context "with default options" do
    it "should exit unsuccessfully if no Passe key file was specified" do
      view_passe file: ""
      expect(command).not_to be_successfully_executed
      expect(stderr).to match(/^ERROR:.*was called with no arguments/)
    end

    it "should show the specified Passe key" do
      view_passe key: secret, file: "passe.key"
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
      view_passe "--no-header", key: secret, file: "passe.key"
      expect(command).to be_successfully_executed
      expect(stdout).not_to match(/A \|.*\nB \|/m)
      expect(stdout).not_to match(/^\s+(- )+\s*$/)
    end

    it "can be customized to not show colors" do
      view_passe "--no-color", key: secret, file: "passe.key"
      expect(command).to be_successfully_executed

      lines_with_colors = stdout.lines.select do |line|
        line =~ /\e\[.*?m.*\e\[0m/
      end
      expect(lines_with_colors.count).to eq 0
    end

    it "can be customized to show a different subgrid" do
      view_passe "-t alphanum", key: secret, file: "passe.key"
      expect(command).to be_successfully_executed
      expect(try_extracting_grid_str(stdout).length).to eq 26**2
    end

    it "can be customized to output using a different format/outputter" do
      view_passe "--no-header", "-f html", key: secret, file: "passe.key"
      expect(command).to be_successfully_executed
      expect(stdout).to match(/<body.*?>/)
      expect(stdout.scan(/<span>.<\/span>/).count).to eq 200
      expect(stdout).not_to include(('A'..'T').to_a.join(" "))
    end

    it "secret key can be supplied with CLI arguments itself" do
      view_passe "-s #{secret}", file: "passe.key"
      expect(command).to be_successfully_executed
      expect(try_extracting_grid_str(stdout).length).to eq 200
    end
  end
end
