module Dominion
  class Player
    def initialize
      @deck = []
      @discard_pile = []
      @hand = []
      @played = []
      @pending_duration_cards = []
    end
    
    def discard(card, options = {})
      found = @hand.delete card
      raise 'Hand does not contain card: ' + card unless found
      to = options[:to] || :discard

      case to
      when :deck
        @deck.push card
      when :discard
        @discard_pile.push card
      else
        raise 'Cannot discard to: ' + to
      end
    end
    
  end
end
