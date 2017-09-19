Aruba.configure do |config|
  config.startup_wait_time = 0.7
  config.io_wait_timeout = 1
  config.exit_timeout = 1
  config.activate_announcer_on_command_failure = [:command, :stdout, :stderr]
end

