module Passcard
  module ArubaHelpers
    SECRET = "secret-word"

    def command
      last_command_started
    end

    def status
      command.exit_status
    end

    def stdout
      command.stdout
    end

    def stderr
      command.stderr
    end

    def directory
      command.working_directory
    end

    def secret
      SECRET
    end
  end
end
