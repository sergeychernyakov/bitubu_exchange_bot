module Arke::Strategy

  # Base class for all strategies
  class Base

    def initialize(config)
      @config = config
      @volume_ratio = config['volume_ratio']
      @spread = config['spread']
      @price_ratio = config['price_ratio']
      @p_precision = config['p_precision']
      @a_precision = config['a_precision']
    end

    #
    # Processes orders and decides what action should be sent to @target
    #
    # @param [Hash] hash of the sources and targets
    def call(dax, &block)
      sources = dax.select { |k, _v| !k.to_s.start_with?('target') }
      targets = dax.select { |k, _v| k.to_s.start_with?('target') }

      targets.each do |target_name, target|
        ob = merge_orderbooks(sources, target.market)
        ob = scale_amounts(ob)
        open_orders = target.open_orders
        diff = open_orders.get_diff(ob)
        process_orders(target_name, diff, open_orders, &block)
      end
    end

    private

    def merge_orderbooks(sources, market)
      ob = Arke::Orderbook.new(market)

      sources.each do |_key, source|
        source_book = source.orderbook.clone

        # discarding 1st level
        source_book[:sell].shift
        source_book[:buy].shift

        ob.merge!(source_book)
      end

      ob
    end

    #
    # Processes orders
    #
    # @param [Symbol] target name
    # @param [Array] difference
    # @param [Arke::OpenOrders] open orders
    # @param [block] block
    #
    def process_orders(target_name, diff, open_orders, &block)
      [:buy, :sell].each do |side|
        create = diff[:create][side]
        delete = diff[:delete][side]
        update = diff[:update][side]

        if !create.length.zero?
          order = create.first
          yield Arke::Action.new(:order_create, target_name, { order: order })
        elsif !delete.length.zero?
          yield Arke::Action.new(:order_stop, target_name, { id: delete.first })
        elsif !update.length.zero?
          order = update.first
          if order.amount > 0.0
            yield Arke::Action.new(:order_create, target_name, { order: order })
          else
            new_amount = (open_orders.price_amount(side, order.price) + order.amount).round(@a_precision)
            new_order = Arke::Order.new(order.market, order.price, new_amount, order.side)
            open_orders.price_level(side, order.price).each do |id, _ord|
              yield Arke::Action.new(:order_stop, target_name, { id: id })
            end
            yield Arke::Action.new(:order_create, target_name, { order: new_order })
          end
        end
      end
    end

    def scale_amounts(orderbook)
      ob = Arke::Orderbook.new(orderbook.market)
      [:buy, :sell].each do |side|
        orderbook[side].each do |price, amount|
          price = (price).to_f.round(@p_precision)
          ob[side][price] = amount * @volume_ratio
        end
      end

      ob
    end
  end
end
