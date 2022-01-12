# frozen_string_literal: true

module Arke
  module Exchange
    # Base class for all exchanges
    class Base
      def print
        return unless @orderbook

        puts "Exchange #{@driver} market: #{@market}"
        puts @orderbook.print(:buy)
        puts @orderbook.print(:sell)
      end

      def build_error(response)
        JSON.parse(response.body)
      rescue StandardError => e
        if response
          "Code: #{response.env.status} Message: #{response.env.reason_phrase}"
        else
          "StandardError Message: #{e.message}"
        end
      end
    end
  end
end
