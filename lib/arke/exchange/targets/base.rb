# frozen_string_literal: true

module Arke::Exchange::Targets
  # Base class for all exchanges
  class Base < Arke::Exchange::Base
    attr_reader :queue, :min_delay, :open_orders, :market
    attr_accessor :timer

    def initialize(opts)
      @market           = opts['market']
      @driver           = opts['driver']
      @api_key          = opts['key']
      @secret           = opts['secret']
      @host             = opts['host']
      @base_currency    = opts['baseCurrency']
      @quote_currency   = opts['quoteCurrency']
      @price_precision  = opts['price_precision']
      @amount_precision = opts['amount_precision']

      @queue            = EM::Queue.new
      @timer            = nil

      rate_limit = opts['rate_limit'] || 1.0
      rate_limit = 1.0 if rate_limit <= 0
      @min_delay = 1.0 / rate_limit

      @open_orders = Arke::OpenOrders.new(@market)
    end

    def get_open_orders; end
    def create_order; end
    def start; end
    def stop_order; end
  end
end
