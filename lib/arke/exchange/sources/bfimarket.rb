require 'eventmachine'
require 'orderbook'
require 'json'
require 'openssl'

module Arke::Exchange::Sources
  class Bfimarket < Base
    attr_reader :last_update_id
    attr_accessor :orderbook

    def initialize(opts)
      super

      @url = "wss://stream.binance.com/ws/zilusdt@depth@100ms"
      @connection = Faraday.new("https://www.binance.com") do |builder|
        builder.adapter :em_synchrony
      end

      @conn2 = Faraday.new('https://www.binance.com/')

      @orderbook = Arke::Orderbook.new(@market)
      @last_update_id = 0
      @rest_api_connection = Faraday.new("https://#{opts['host']}") do |builder|
        builder.adapter :em_synchrony
        builder.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      end

      @min_price = opts['min_price']
      @max_price = opts['max_price']

      @ws_countdown = 3
      @origin_depth = 500
    end

    # TODO: remove EM (was used only for debug)
    def start
      get_snapshot

      Thread.new do
        loop do
          sleep 30
          get_snapshot_2
        end
      end

      start_websocket_scribe
    end

    def start_websocket_scribe
      EM.run do
        @ws = Faye::WebSocket::Client.new(@url, nil, ping: 120)

        @ws.on :open do |e|
          p [:connected]
        end

        @ws.on :message do |e|
          # p [:message, e.data]
          on_message e
        end

        @ws.on :error do |e|
          p [:error, e.inspect]
        end

        @ws.on :ping do |e|
          p [:ping, e.message]
          @ws.pong
        end

        @ws.on :close do |e|
          p [:close, e.code, e.reason]

          @ws = nil
          # restart the connection
          start_websocket_scribe
        end
      end
    end

    def on_message(mes)
      data = JSON.parse(mes.data)
      return if @last_update_id >= data['U']

      @last_update_id = data['u']
      process(data['b'], :buy) unless data['b'].empty?
      process(data['a'], :sell) unless data['a'].empty?
    end

    def process(data, side)
      data.each do |order|
        if order[1].to_f.zero?
          @orderbook.delete(build_order(order, side))
          next
        end

        orderbook.update(
          build_order(order, side)
        )

        if (side == :sell)
          if orderbook.book[:sell].size > @origin_depth
            orderbook.book[:sell].delete orderbook.book[:sell].last[0]
          end
        else
          if orderbook.book[:buy].size > @origin_depth
            orderbook.book[:buy].delete orderbook.book[:buy].last[0]
          end
        end
      end
    end

    def build_order(data, side)
      Arke::Order.new(
        @market,
        data[0].to_f,
        data[1].to_f,
        side
      )
    end

    def range (min, max)
      rand * (max-min) + min
    end

    def get_snapshot
      snapshot = JSON.parse(@connection.get("api/v1/depth?symbol=ZILUSDT&limit=50").body)
      @last_update_id = snapshot['lastUpdateId']
      Arke::Log.debug ">>>>>>>>>>>>>>>>>>>>> #{snapshot.empty?}"
      if !snapshot.empty?
        random_price = range(@min_price, @max_price)
        Arke::Log.debug ">>>>>>>>>>>>>>>>>>>>> #{random_price}"
        Arke::Log.debug ">>>>>>>>>>>>>>>>>>>>> #{snapshot['bids'][0][0].to_f}"
        Arke::Log.debug ">>>>>>>>>>>>>>>>>>>>> BIDS #{snapshot['bids']}"
        Arke::Log.debug ">>>>>>>>>>>>>>>>>>>>> ASKS #{snapshot['asks']}"
        difference_bid = random_price - snapshot['bids'][0][0].to_f
        data_bid = []
        snapshot['bids'].each{ |pair| data_bid << [pair[0].to_f + difference_bid, pair[1]] }
        process(data_bid, :buy)

        difference_ask = random_price - snapshot['asks'][0][0].to_f
        data_ask = []
        snapshot['asks'].each{ |pair| data_ask << [pair[0].to_f + difference_ask, pair[1]] }
        process(data_ask, :sell)
      end
    end

    def get_snapshot_2
      snapshot = JSON.parse(@conn2.get("api/v1/depth", symbol: 'ZILUSDT', limit: 50).body)
      @last_update_id = snapshot['lastUpdateId']
      Arke::Log.debug ">>>>>>>>>>>>>>>>>>>>> #{snapshot.empty?}"
      if !snapshot.empty?
        random_price = range(@min_price, @max_price)
        Arke::Log.debug ">>>>>>>>>>>>>>>>>>>>> #{random_price}"
        Arke::Log.debug ">>>>>>>>>>>>>>>>>>>>> #{snapshot['bids'][0][0].to_f}"
        Arke::Log.debug ">>>>>>>>>>>>>>>>>>>>> BIDS #{snapshot['bids']}"
        Arke::Log.debug ">>>>>>>>>>>>>>>>>>>>> ASKS #{snapshot['asks']}"
        difference_bid = random_price - snapshot['bids'][0][0].to_f
        data_bid = []
        snapshot['bids'].each{ |pair| data_bid << [pair[0].to_f + difference_bid, pair[1]] }
        process(data_bid, :buy)

        difference_ask = random_price - snapshot['asks'][0][0].to_f
        data_ask = []
        snapshot['asks'].each{ |pair| data_ask << [pair[0].to_f + difference_ask, pair[1]] }
        process(data_ask, :sell)
      end
    end

    def create_order(order)
      timestamp = Time.now.to_i * 1000
      body = {
        symbol: @market.upcase,
        side: order.side.upcase,
        type: 'LIMIT',
        timeInForce: 'GTC',
        quantity: order.amount.to_f,
        price: order.price.to_f,
        recvWindow: '5000',
        timestamp: timestamp
      }

      post('api/v3/order', body)
    end

    def generate_signature(data, timestamp)
      query = ""
      data.each { |key, value| query << "#{key}=#{value}&" }
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), @secret, query.chomp('&'))
    end

    private

    def post(path, params = nil)
      request = @rest_api_connection.post(path) do |req|
        req.headers['X-MBX-APIKEY'] = @api_key
        req.body = URI.encode_www_form(generate_body(params))
      end

      Arke::Log.fatal(build_error(request)) if request.env.status != 200
      request
    end

    def generate_body(data)
      query = ""
      data.each { |key, value| query << "#{key}=#{value}&" }
      sig = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), @secret, query.chomp('&'))
      data.merge(signature: sig)
    end
  end
end
