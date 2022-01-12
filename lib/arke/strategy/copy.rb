require 'action'

module Arke::Strategy
  # This class implements basic copy strategy behaviour
  # * aggreagates orders from sources
  # * push order to target
  class Copy < Base
    ORDER_AMOUNT_LIMIT = 0.0
  end
end
