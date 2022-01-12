require 'action'

module Arke::Strategy
  # This class implements basic copy strategy behaviour
  # * aggreagates orders from sources
  # * push order to target
  class Aaaa < Base
    ORDER_AMOUNT_LIMIT = 0.0
  end
end
