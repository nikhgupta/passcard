module Passe
  module TestHelpers
    def dummy_passe(options = {})
      Passe::Generator.new("dummy", options)
    end

    def with_dummy_passe(options = {})
      passe = dummy_passe(options)
      yield(passe, passe.options, passe.run)
    end

    def generate_passe(*args, key: nil)
      run_command "passe generate #{args.join(" ")}"
      type(key) if key && command.output =~ /provide a secret key/i
    end

    def view_passe(*args, key: nil, file: nil)
      file ||= "passe.key"
      run_command "passe view #{file} #{args.join(" ")}"
      type(key) if key && command.output =~ /provide your secret key/i
    end
  end
end
