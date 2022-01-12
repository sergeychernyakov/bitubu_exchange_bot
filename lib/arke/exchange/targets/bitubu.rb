require 'exchange/targets/base'
require 'open_orders'

module Arke::Exchange::Targets
  # This class holds Rubykube Exchange logic implementation
  class Bitubu < Base

    # Takes config (hash), strategy(+Arke::Strategy+ instance)
    # * +strategy+ is setted in +super+
    # * creates @connection for RestApi
    def initialize(config)
      super
      @config = config
      @connection = Faraday.new("#{config['host']}/api/v2") do |builder|
        # builder.response :logger
        builder.response :json
        builder.adapter :em_synchrony
      end
    end

    def start
      get_open_orders
    end

    # Ping the api
    def ping
      # @connection.get '/oauth/identity/ping'
    end

    # * gets +order+ via RestApi
    def get_open_orders()
      response = get(
          "orders?market=#{@market}&state=wait&limit=1000"
      ).body

      if (response)
        response.each do |order|
          @open_orders.add_order(
              Arke::Order.new(@market.to_s, order['price'].to_f, order['remaining_volume'].to_f, order['side'] == "buy" ? :buy : :sell),
              order['id']
          )
        end
      end
    end

    # Takes +order+ (+Arke::Order+ instance)
    # * creates +order+ via RestApi
    def create_order(order)
      begin
        response = post(
            'orders',
            {
                market: order.market,
                side: order.side.to_s,
                volume: order.amount.round(@config['amount_precision']),
                price: order.price.round(@config['price_precision'])
            }
        )
        @open_orders.add_order(order, response.env.body['id']) if response.env.status == 201 && response.env.body['id']
      rescue
        return nil
      end
      response
    end

    # Takes +order+ (+Arke::Order+ instance)
    # * cancels +order+ via RestApi
    def stop_order(id)
      begin
        response = post(
            "order/delete?id=#{id}"
            # "orders/delete?id=#{id}" for 2.x
        )
        @open_orders.remove_order(id)
      rescue
        @open_orders.remove_order(id)
        return nil
      end
      response
    end

    private

    # Helper method to perform post requests
    # * takes +conn+ - faraday connection
    # * takes +path+ - request url
    def get(path, params = nil)
      response = @connection.get do |req|
        req.headers = generate_headers
        req.url path
      end
      Arke::Log.fatal(build_error(response)) if response.env.status != 201
      response
    end

    # Helper method to perform post requests
    # * takes +conn+ - faraday connection
    # * takes +path+ - request url
    # * takes +params+ - body for +POST+ request
    def post(path, params = nil)
      response = @connection.post do |req|
        req.headers = generate_headers
        req.url path
        req.body = params.to_json
      end
      Arke::Log.fatal(build_error(response)) if response.env.status != 201
      response
    end

    # Helper method, generates headers to authenticate with +api_key+
    def generate_headers
      nonce = Time.now.to_i.to_s
      {
        'X-Auth-Apikey' => @api_key,
        'X-Auth-Nonce' => nonce,
        'X-Auth-Signature' => OpenSSL::HMAC.hexdigest('SHA256', @secret, nonce + @api_key),
        'Content-Type' => 'application/json'
      }
    end
  end
end
