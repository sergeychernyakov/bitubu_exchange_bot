require 'clamp'
require 'yaml'

require 'command/root'
require 'arke'

module Arke
  module Command
    def run!
      load_configuration
      Arke::Log.define
      Root.run
    end
    module_function :run!

    def load_configuration
      strategy_path = if Dir.pwd.split('/').last == 'markets'
        '../config/strategy.yaml'
      else
        './config/strategy.yaml'
      end
      config = YAML.load_file(strategy_path)

      p config['strategy']
      Arke::Configuration.define { |c| c.strategy = config['strategy'] }
    end
    module_function :load_configuration

    # NOTE: we can add more features here (colored output, etc.)
  end
end
