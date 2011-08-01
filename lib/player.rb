module Dominion
  class Player
    
    attr_reader :game, :position, :identity,
      :deck, :discard_pile, :hand,
      :actions_in_play, :treasures_in_play, :durations_in_play,
      :actions_available, :buys_available, :coins_available
    
    def initialize(game, position, identity)
      @game = game
      @position = position
      @identity = identity
      @deck = []
      @discard_pile = []
      @hand = []
      @actions_in_play = []
      @treasures_in_play = []
      @durations_in_play = []
      @actions_available = 0
      @buys_available = 0
      @coins_available = 0
    end
    
    def prepare(options = {})
      @deck = []
      7.times { @deck.push game.draw_from_supply Copper, self }
      3.times { @deck.push game.draw_from_supply Estate, self }
      @deck.shuffle!

      @hand = []
      draw_hand
    end
    
    def start_turn
      raise "Cannot start turn in #{phase} phase" unless setup_phase?
      @actions_available = 1
      @buys_available = 1
      @coins_available = 0
      game.phase = :action
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
    
    # def discard(card, options = {})
    #   found = @hand.delete card
    #   raise "Hand does not contain card: #{card}" unless found
    #   to = options[:to] || :discard
    # 
    #   case to
    #   when :deck
    #     @deck.push card
    #   when :discard
    #     @discard_pile.push card
    #   else
    #     raise 'Cannot discard to: ' + to
    #   end
    # end
    
    def play_all_treasures
      treasure_cards = hand.find_all { |card| card.treasure? }
      treasure_cards.each { |card| play card }
    end
    
    def play(card)
      is_card_class = card.is_a?(Class) && card.ancestors.include?(Card)
      if is_card_class
        # choose an instance from the player's hand of the given class
        card_class = card
        card = hand.find {|card| card.is_a? card_class}
        raise "No card of type #{card_class} found in hand" unless card
      end

      raise "#{card} is not a valid card" unless card.is_a? Card
      raise "#{card} is not the player's own card!" unless card.player == self
      raise "#{card} is not a card in hand" unless hand.include? card
      
      raise "#{card} is not playable" unless card.action? || card.treasure?
      raise "#{card} is an action card, but currently in #{phase} phase" if card.action? && !action_phase?
      
      game.phase = :buy if action_phase? && card.treasure?   # automatically move to buy phase
      raise "#{card} is a treasure card, but currently in #{phase} phase" if card.treasure? && !buy_phase?

      hand.delete card
      
      if action_phase? && card.action?
        @actions_available += card.actions
        @buys_availalbe += card.buys
        @coins_available += card.coins
        card.do_action
      elsif buy_phase? && card.treasure?
        @buys_available += card.buys
        @coins_available += card.coins
        card.do_buy
      end
    end
    
    def name
      if identity.nil?
        "Player #{position}"
      else
        identity.to_s
      end
    end
    
    def to_s
      name
    end
    
    def method_missing(method, *args)
      @game.send method, *args
    end
    
  end
end
