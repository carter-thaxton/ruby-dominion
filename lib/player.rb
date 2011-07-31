module Dominion
  class Player
    
    attr_reader :game, :position, :identity, :deck, :discard_pile, :hand, :in_play, :duration_in_play
    
    def initialize(game, position, identity)
      @game = game
      @position = position
      @identity = identity
      @deck = []
      @discard_pile = []
      @hand = []
      @in_play = []
      @duration_in_play = []
    end
    
    def setup(options = {})
      @deck = []
      7.times { @deck.push game.draw_from_supply Copper, self }
      3.times { @deck.push game.draw_from_supply Estate, self }
      @deck.shuffle!

      @hand = []
      draw_hand
    end
    
    def draw_hand
      5.times { draw }
    end
    
    def draw
      if @deck.empty?
        @deck = @discard
        @discard = []
        @deck.shuffle!
      end
      card = @deck.shift
      @hand.push card if card
      card
    end
    
    def discard(card, options = {})
      found = @hand.delete card
      raise "Hand does not contain card: #{card}" unless found
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
    
    def to_s
      if identity.nil?
        "Player #{position}"
      else
        identity
      end
    end
    
    def method_missing(method, *args)
      @game.send method, *args
    end
    
  end
end
