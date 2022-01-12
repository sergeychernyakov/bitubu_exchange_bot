module Arke
  module Command
    class Start < Clamp::Command

      option "--dry", :flag, "dry run on the target"
      parameter "Market_Name", "Arke Strategy Id", attribute_name: :strategy

      def execute
        puts "#{strategy.upcase} Liquidity Bot is running..."
        config = Arke::Configuration.require!(strategy)
        config['dry'] = dry?
        config['targets'].each{ |target| target['driver'] = 'bitfaker' } if dry? 

        reactor = Arke::Reactor.new(config)
        reactor.run
      end
    end
  end
end
