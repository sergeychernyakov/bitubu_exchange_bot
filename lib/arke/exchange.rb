# frozen_string_literal: true

require 'exchange/sources/base'
require 'exchange/sources/bitfinex'
require 'exchange/sources/binance'
require 'exchange/sources/bitubu'
require 'exchange/sources/bfimarket'
require 'exchange/targets/base'
require 'exchange/targets/bitfaker'
require 'exchange/targets/bitubu'
require 'exchange/targets/cointiger'
require 'exchange/targets/latoken'

module Arke
  # Exchange module, contains Exchanges drivers implementation
  module Exchange
    #
    # Fabric method, Creates proper Sourse Exchange instance
    # * takes +strategy+ (+Arke::Strategy+) and passes to Exchange initializer
    # * takes +config+ (hash) and passes to Exchange initializer
    # * takes +config+ and resolves correct Exchange class with +exchange_class+ helper
    def self.create_source(config)
      exchange_class("Sources::#{config['driver']}").new(config)
    end

    #
    # Fabric method, Creates proper Target Exchange instance
    # * takes +strategy+ (+Arke::Strategy+) and passes to Exchange initializer
    # * takes +config+ (hash) and passes to Exchange initializer
    # * takes +config+ and resolves correct Exchange class with +exchange_class+ helper
    def self.create_target(config)
      exchange_class("Targets::#{config['driver']}").new(config)
    end

    # Takes +dirver+ - +String+
    # Resolves correct Exchange class by it's name
    def self.exchange_class(driver)
      Arke::Exchange.const_get(driver.split('::').map(&:capitalize).join('::'))
    end
  end
end
