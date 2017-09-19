module Passe
  class CLI < Thor
    def self.exit_on_failure?; true; end

    desc "generate", "Generate a Passe Key file."
    method_option :identity_file, type: :string, aliases: "-i", default: "./passe.key"
    method_option :secret_key, type: :string, aliases: "-s"
    method_option :charset, type: :string, aliases: "-c"
    method_option :force, type: :boolean, aliases: "-f"
    def generate
      file = options[:identity_file]
      if File.exist?(file) && !options[:force]
        raise Passe::Error, "Identity file exists!"
      elsif File.exist?(file)
        say_status "WARNING", "Overwriting file at: #{file}", :yellow
      end

      unless secret = options[:secret_key]
        message = "Please, provide a secret key [Enter for none]:"
        secret  = ask(message).strip
        puts
      end

      opts = options.except(:secret_key, :identity_file) || {}
      Passe.create!(secret, file, opts)
      say_status "SUCCESS", "Created Passe key in: #{file}"
    end

    desc "view IDENTITY_FILE", "View different grids stored in your Passe Key file."
    method_option :header,     type: :boolean, default: true
    method_option :color,      type: :string,  default: :passe
    method_option :type,       type: :string,  default: :card, aliases: "-t"
    method_option :secret_key, type: :string,  aliases: "-s"
    method_option :format,     type: :string,  aliases: "-f", default: "ascii"
    def view(identity_file)
      unless secret = options[:secret_key]
        message = "Please, provide your secret key [Enter for none]:"
        secret  = ask(message).strip
        puts
      end

      data = Passe.read!(secret, identity_file)
      puts data.send("to_#{options[:format]}", options)
    rescue OpenSSL::Cipher::CipherError
      message  = "Seems like you entered the wrong secret key,\n"
      message += "or this does not seem to be a valid Passe."
      raise Passe::Error, message
    end
  end
end
