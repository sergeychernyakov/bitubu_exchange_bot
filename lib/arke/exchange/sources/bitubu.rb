# frozen_string_literal: true

module Arke::Exchange::Sources
  class Bitubu < Base
    #
    # Starts source workings
    #
    def start
      start_websocket_scribe("wss://wss.bitubu.com?stream=#{@market.downcase}.update")
    end

    #
    # Event working on getting message from websocket
    #
    def on_message(message)
      data = JSON.parse(message.data)
      return unless data.is_a?(Array) && data[0] == "#{@market.downcase}.update"
      data = data[1]
      process(data['bids'], :buy) unless data['bids'].empty?
      process(data['asks'], :sell) unless data['asks'].empty?
    end
  end
end
