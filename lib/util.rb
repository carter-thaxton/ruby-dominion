module Dominion
  module Util

    def is_card_class(card)
      card.is_a?(Class) && card.ancestors.include?(Card)
    end
    
  end
end
