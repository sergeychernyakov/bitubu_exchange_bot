# frozen_string_literal: true

require 'exchange/targets/base'
require 'open_orders'

module Arke
  module Exchange
    module Targets
      # This class holds Rubykube Exchange logic implementation
      class Cointiger < Base
        # Takes config (hash), strategy(+Arke::Strategy+ instance)
        # * +strategy+ is setted in +super+
        # * creates @connection for RestApi
        def initialize(config)
          super
          @config = config

          @connection = Faraday.new("#{config['host']}exchange/trading/api/v2") do |builder|
            builder.response :json
            builder.adapter :em_synchrony
          end
        end

        def start
          get_open_orders
        end

        #
        # * gets +order+ via RestApi
        #
        def get_open_orders
          response = get('order/orders', get_open_orders_params).body
          return @open_orders unless response && response['data']

          response['data'].each do |order|
            @open_orders.add_order(
              Arke::Order.new(
                @market.to_s,
                order['price'].to_f,
                order['volume'].to_f,
                order['side'] =~ 'buy' ? :buy : :sell
              ),
              order['id']
            )
          end
          @open_orders
        end

        # Takes +order+ (+Arke::Order+ instance)
        # * creates +order+ via RestApi
        # example: create_order(Arke::Order.new(@market.to_s, 2.3, 68, :sell)) # trxbitcny
        def create_order(order)
          response = post(
            'order',
            {
              'symbol' => order.market,
              'side' => order.side.upcase,
              'volume' => order.amount.round(@config['amount_precision']),
              'price' => order.price.round(@config['price_precision']),
              'type' => 1
            }
          )

          if response.env.status == 201 && response.body['data'] && response.body['data']['order_id']
            @open_orders.add_order(order, response.body['data']['order_id'])
          end
        rescue
          Arke::Log.fatal(build_error(response))
          nil
        end

        # Takes +order+ (+Arke::Order+ instance)
        # * cancels +order+ via RestApi
        def stop_order(id)
          response = post(
            'order/batch_cancel', { 'orderIdList' => "{\"#{@market}\":[\"#{id}\"]}" }
          )
          @open_orders.remove_order(id)
          response
        rescue
          @open_orders.remove_order(id)
          Arke::Log.fatal(build_error(response))
          nil
        end

        private

        #
        # Helper method to perform post requests
        #
        # @param path [String] request path
        # @param params [Hash] params
        # @return [String] response
        def get(path, params = {})
          params['time']  ||= DateTime.now.strftime('%Q')
          params['sign']    = get_sign(params)
          params['api_key'] = @api_key
          query = params.map { |k, v| "#{k}=#{v}" }.join('&')
          path =~ /\?/ ? query.prepend('&') : query.prepend('?')
          response = @connection.get do |req|
            req.url path + query
          end
          Arke::Log.fatal(build_error(response)) if response.env.status != 201
          response
        end

        #
        # Params for get_open_orders method
        #
        # @return [Hash] params
        def get_open_orders_params
          {
            'symbol' => @market.to_s,
            'states' => 'new,filled,part_filled',
            'types' => 'buy-limit,sell-limit'
          }
        end

        #
        # Signs params for the private REST API
        #
        # @param params [Hash] params
        def get_sign(params = {})
          query = params.sort.flatten
          OpenSSL::HMAC.hexdigest('SHA512', @secret, query.join('') + @secret)
        end

        #
        # Helper method to perform post requests
        # * takes +conn+ - faraday connection
        # * takes +path+ - request url
        # * takes +params+ - body for +POST+ request
        #  time, token and sign are put into get parameter.
        def post(path, body_params = {})
          query_params = {}
          query_params['time']  ||= DateTime.now.strftime('%Q')
          query_params['sign']    = get_sign(query_params.merge(body_params))
          query_params['api_key'] = @api_key
          query = query_params.map { |k, v| "#{k}=#{v}" }.join('&')
          path =~ /\?/ ? query.prepend('&') : query.prepend('?')
          response = @connection.post do |req|
            req.url path + query
            req.body = body_params
          end
          Arke::Log.fatal(build_error(response)) if response.env.status != 201
          response
        end
      end
    end
  end
end
