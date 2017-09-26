require 'simplecov'

require "bundler/setup"
require 'aruba/rspec'
require "passcard"

Dir.glob(Passcard.root.join("spec", "support", "**", "*.rb")).each{|f| require f}

RSpec.configure do |config|
  config.include Passcard::TestHelpers
  config.include Passcard::ArubaHelpers, type: :aruba

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
    c.include_chain_clauses_in_custom_matcher_descriptions = true
  end
end
