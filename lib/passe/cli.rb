module Passe
  class CLI
    def self.run(options, *args)
      seed = args.join(" ")
      puts Passe::Generator.new(seed, options)
    # rescue Passe::Error => e
    #   puts "[ERROR]: #{e.message}"
    # rescue StandardError => e
    #   puts "[FATAL]: #{e.message}"
    end
  end
end
