# frozen_string_literal: true

require 'exchange/base'

module Arke::Exchange
  module Sources
    # Base class for all exchanges
    class Base < Arke::Exchange::Base
      attr_reader :queue, :min_delay, :open_orders, :market, :orderbook
      attr_accessor :timer

      def initialize(opts)
        @market         = opts['market']
        @driver         = opts['driver']
        @api_key        = opts['key']
        @secret         = opts['secret']
        @base_currency  = opts['baseCurrency']
        @quote_currency = opts['quoteCurrency']
        @origin_depth   = opts['depth']
        @queue          = EM::Queue.new
        @timer          = nil
        @config         = opts

        rate_limit = opts['rate_limit'] || 1.0
        rate_limit = 1.0 if rate_limit <= 0
        @min_delay = 1.0 / rate_limit

        @open_orders = Arke::OpenOrders.new(@market)
        @orderbook = Arke::Orderbook.new(@market)
      end

      def on_message; end
      def start; end

      #
      # Builds Arke::Order
      #
      # @param data [Array] websoket message { bids: [] || asks: [] }
      # @param side [Symbol] :sell || :buy
      #
      # @return [Arke::Order] order
      def build_order(data, side)
        Arke::Order.new(@market, data[0].to_f, data[1].to_f, side)
      end

      #
      # Processes 
      #
      # @param data [Array] websoket message { bids: [] || asks: [] }
      # @param side [Symbol] :sell || :buy
      def process(data, side)
        data.each do |order|
          if order[1].to_f.zero?
            @orderbook.delete(build_order(order, side))
            next
          end

          @orderbook.update(build_order(order, side))

          if (side == :sell)
            if @orderbook.book[:sell].size > @origin_depth
              @orderbook.book[:sell].delete @orderbook.book[:sell].last[0]
            end
          else
            if @orderbook.book[:buy].size > @origin_depth
              @orderbook.book[:buy].delete @orderbook.book[:buy].last[0]
            end
          end
        end
      end

      #
      # Starts websocket
      #
      # @param wss_url [String] websocket url
      def start_websocket_scribe(wss_url)
        EM.run do
          @ws = Faye::WebSocket::Client.new(wss_url, nil, ping: 120)

          @ws.on :open do |e|
            p [:connected]
          end

          @ws.on :message do |e|
            on_message e
          end

          @ws.on :error do |e|
            p [:error, e.message]
          end

          @ws.on :ping do |e|
            p [:ping, e.message]
            @ws.pong
          end

          @ws.on :close do |e|
            p [:close, e.code, e.reason]

            @ws = nil
            # restart the connection
            start_websocket_scribe(wss_url)
          end
        end
      end
    end
  end
end
