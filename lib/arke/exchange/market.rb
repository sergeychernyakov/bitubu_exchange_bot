# frozen_string_literal: true

module Arke
  module Exchange
    # This class holds Exchange Currency logic implementation
    class Market

      MARKETS = {
        'BTCUSDT'    => ['BTC','USDT'],
        'LUCHOWUSDT' => ['LUCHOW','USDT'],
        'TRXUSDT'    => ['TRX','USDT']
      }.freeze

      def self.market_currencies_symbols(market_name)
        base_currency = market_name.to_s.upcase.chomp("USDT")
        if base_currency
          [base_currency, 'USDT']
        else
           MARKETS[market_name]
        end
      end
    end
  end
end
