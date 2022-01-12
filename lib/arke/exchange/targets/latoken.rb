# frozen_string_literal: true

require 'exchange/targets/base'
require 'exchange/market'
require 'exchange/currency'
require 'open_orders'

module Arke::Exchange::Targets
  # This class holds Rubykube Exchange logic implementation
  class Latoken < Base

    def initialize(opts)
      super
      @rest_api_connection = Faraday.new(@host) do |builder|
        builder.adapter :em_synchrony
        builder.headers['Content-Type'] = 'application/json'
      end

      set_currencies_ids
    end

    #
    # Takes +order+ (+Arke::Order+ instance)
    # * creates +order+ via RestApi
    def create_order(order)
      response = post(
          'v2/auth/order/place',
          {
            'baseCurrency' => @base_currency,
            'quoteCurrency' => @quote_currency,
            'side' => order.side.to_s.upcase,
            'condition' => 'GOOD_TILL_CANCELLED',
            'type' => 'LIMIT',
            'price' => order.price.round(@price_precision),
            'quantity' => order.amount.round(@amount_precision)
          }
      )
      @open_orders.add_order(order, response.env.body['id']) if response.env.status == 201 && response.env.body['id']
      response
    rescue => e
      Arke::Log.fatal(build_error(response))
    end

    #
    # https://api.latoken.com/v2/auth/order/pair/{currency}/{quote}/active
    # * gets +order+ via RestApi
    def get_open_orders
      response = get("v2/auth/order/pair/#{@base_currency}/#{@quote_currency}/active")
      orders = JSON.parse(response.body)
      orders.each do |order|
        order_remaining_volume = order['quantity'].to_f - order['filled'].to_f
        next unless order_remaining_volume.positive?
        @open_orders.add_order(
            Arke::Order.new(@market.to_s, order['price'].to_f, order_remaining_volume, order['side'] == "BUY" ? :buy : :sell),
            order['id']
        )
      end
      @open_orders
    end

    #
    # Ping the api
    #
    def ping
      get('pair/available').success?
    end

    def start
      return unless @base_currency && @quote_currency
      get_open_orders
    end

    # Takes +order+ (+Arke::Order+ instance)
    # * cancels +order+ via RestApi
    def stop_order(id)
      begin
        response = post("v2/auth/order/cancel", { 'id' => id })
        @open_orders.remove_order(id)
      rescue
        @open_orders.remove_order(id)
        return nil
      end
      response
    end

    private

    #
    # Gets currencies
    #
    # @return [Array] Currency id, name, tag, status
    def currencies
      @currencies ||= begin
        response = get('v2/currency').body
        currencies = JSON.parse(response)
        currencies.map do |currency|
          Arke::Exchange::Currency.new(
            id: currency['id'],
            name: currency['name'],
            tag: currency['tag'],
            status: currency['status'],
            decimals: currency['decimals'],
            min_amount: currency['minTransferAmount']
          )
        end
      end
    end

    # Helper method to perform post requests
    # * takes +conn+ - faraday connection
    # * takes +path+ - request url
    def get(path, params = nil)
      response = @rest_api_connection.get do |req|
        req.headers = generate_headers(path)
        req.url path
      end
      Arke::Log.fatal(build_error(response)) if response.env.status != 201
      response
    end

    #
    # Helper method, generates headers to authenticate with +api_key+
    #
    def generate_headers(path, http_method = 'GET', data = {})
      params = data.map { |k, v| "#{k}=#{v}" }.join('&')
      {
        'Content-Type'   => 'application/json',
        'X-LA-APIKEY'    => @api_key,
        'X-LA-SIGNATURE' => OpenSSL::HMAC.hexdigest("SHA256", @secret, "#{http_method}/#{path}#{params}")
      }
    end

    # Helper method to perform post requests
    # * takes +conn+ - faraday connection
    # * takes +path+ - request url
    # * takes +params+ - body for +POST+ request
    def post(path, params = {})
      response = @rest_api_connection.post do |req|
        req.headers = generate_headers(path, 'POST', params)
        req.url path
        req.body = params.to_json
      end
      Arke::Log.fatal(build_error(response)) if response.env.status != 201
      response
    end

    #
    # Gets the markets currencies ids from latoken API by tag
    #
    def set_currencies_ids
      base_currency, quote_currency = Arke::Exchange::Market.market_currencies_symbols(@market)
      return unless base_currency && quote_currency
      @base_currency, @quote_currency = currencies.select{ |currency| [base_currency, quote_currency].include?(currency.tag) }.map(&:id)
      [@base_currency, @quote_currency]
    end
  end
end
