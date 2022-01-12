module Arke::Strategy
  # This class implements basic copy strategy behaviour
  # * aggreagates orders from sources
  # * push order to target
  class Bbbb < Base

    ORDER_AMOUNT_LIMIT = 1e-8

    private

    def scale_amounts(orderbook)
      ob = Arke::Orderbook.new(orderbook.market)

      price_rate = Global[@price_ratio].ticker[:last] if @price_ratio
      #price_precision = (Market.find orderbook.market).bid_precision
      price_precision = @p_precision
      amount_precision = @a_precision
      [:buy, :sell].each do |side|
        orderbook[side].each do |price, amount|
          if price_rate
            new_price = (price_rate * price).to_f.round(price_precision)
            ob[side][new_price] = (amount * @volume_ratio).to_f.round(amount_precision)
          else
            raise 'Price Rate not worked'
          end

        end
      end

      ob
    end
  end
end
