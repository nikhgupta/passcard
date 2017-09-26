module Passcard
  module TestHelpers
    def dummy_passcard(options = {})
      Passcard::Generator.new("dummy", options)
    end

    def with_dummy_passcard(options = {})
      passcard = dummy_passcard(options)
      yield(passcard, passcard.options, passcard.run)
    end

    def generate_passcard(*args, key: nil)
      run_command "passcard generate #{args.join(" ")}"
      type(key) if key && command.output =~ /provide a secret key/i
    end

    def view_passcard(*args, key: nil, file: nil)
      file ||= "passcard.key"
      run_command "passcard view #{file} #{args.join(" ")}"
      type(key) if key && command.output =~ /provide your secret key/i
    end
  end
end
