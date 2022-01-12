# frozen_string_literal: true

module Arke
  module Exchange
    # This class holds Exchange Currency logic implementation
    class Currency
      attr_accessor :id, :name, :tag, :status, :decimals, :min_amount

      def initialize(id:, name:, tag:, status:, decimals:, min_amount: 0)
        self.id = id
        self.name = name
        self.tag = tag
        self.status = status
        self.decimals = decimals
        self.min_amount = min_amount
      end
    end
  end
end
