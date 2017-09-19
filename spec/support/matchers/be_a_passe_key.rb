module RSpec::Matchers
  class BeAPasseKey
    include RSpec::Matchers

    def with_secret(key)
      @key = key
      self
    end

    def with_charset_matching(regex)
      @charset_regex = regex
      self
    end

    def has_error(*error)
      @error = error
      self
    end

    def does_not_match?(file)
      file = "tmp/aruba/#{file}"
      data = File.readlines(file)
      expect(data[ 0]).not_to match(/-+ BEGIN PASSE KEY -+/)
      expect(data[-1]).not_to match(/-+ END PASSE KEY -+/)
      expect{ Passe.read!(@key, file) }.to raise_error(*@error)
      return true
    end

    def matches?(file)
      raise 'No secret key provided' if @key.nil?

      file = "tmp/aruba/#{file}"
      @reader = Passe.read!(@key, file)

      has_size_information?
      has_no_private_information?

      has_grid?
      has_numeric_grid?
      has_alphanumeric_grid?

      has_valid_charset?

      return true
    end

    def failure_message
      "Expected '#{@file}' to be a Passe key with secret: #{@key}"
    end

    def failure_message_when_negated
      "Expected '#{@file}' not to be a Passe key"
    end

    def description
      "'#{@file}' should be a Passe key with secret: #{@key}"
    end

    private

    def has_size_information?
      expect(@reader["size"]).to be_a(Array)
      expect(@reader["numeric"]).to be_a(Array)
      expect(@reader["alpha"]).to be_a(Array)
    end

    def has_no_private_information?
      expect(@reader).not_to have_key("identity_file")
      expect(@reader).not_to have_key("encrypted_key")
      expect(@reader).not_to have_key("secret_key")
    end

    def has_grid?
      expect(@reader.grid).to be_a_passe_grid.with_size(@reader.opts['size'])
      expect(@reader.grid.to_str).to match(/\A[!-~]+\z/)
    end

    def has_numeric_grid?
      expect(@reader.numeric_grid).to be_a_passe_grid.with_size(@reader.opts['numeric'])
      expect(@reader.numeric_grid.to_str).to match(/\A[0-9]+\z/)
    end

    def has_alphanumeric_grid?
      expect(@reader.alpha_grid).to be_a_passe_grid.with_size(@reader.opts['alpha'])
      expect(@reader.alpha_grid.to_str).to match(/\A[a-z0-9]+\z/i)
    end

    def has_valid_charset?
      if @charset_regex
        expect(@reader.opts['charset']).to match(@charset_regex)
      else
        expect(@reader.opts['charset']).to match(/\A[!-~]+\z/)
        expect(@reader.opts['charset'].gsub(/[a-z0-9]+/i, '')).not_to be_empty
      end
    end
  end

  def be_a_passe_key
    BeAPasseKey.new
  end
end
