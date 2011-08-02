module Dominion
  class Player
    
    attr_reader :game, :position, :identity,
      :deck, :discard_pile, :hand,
      :actions_in_play, :treasures_in_play,
      :durations_on_first_turn, :durations_on_second_turn,
      :actions_available, :coins_available, :buys_available,
      :vp_tokens, :pirate_ship_tokens,
      :turn
    
    def initialize(game, position, identity)
      @game = game
      @position = position
      @identity = identity
      @deck = []
      @discard_pile = []
      @hand = []
      @actions_in_play = []
      @treasures_in_play = []
      @durations_on_first_turn = []
      @durations_on_second_turn = []
      @actions_available = 0
      @coins_available = 0
      @buys_available = 0
      @vp_tokens = 0
      @pirate_ship_tokens = 0
      @turn = 0
    end
    
    def prepare(options = {})
      @deck = []
      @hand = []

      unless options[:no_cards]
        7.times { @deck << draw_from_supply(Copper, self) }
        3.times { @deck << draw_from_supply(Estate, self) }
        @deck.shuffle!

        draw 5
      end
    end
    
    def start_turn
      raise "Cannot start turn in #{phase} phase" unless setup_phase?
      @turn += 1
      @actions_available = 1
      @coins_available = 0
      @buys_available = 1
      move_to_phase :action
    end
    
    def end_turn
      raise "Cannot end turn in #{phase} phase" unless action_phase? || treasure_phase? || buy_phase?
      move_to_phase :cleanup
      
      @actions_in_play.each { |card| card.on_cleanup }
      @discard_pile += @actions_in_play
      @actions_in_play = []

      @treasures_in_play.each { |card| card.on_cleanup }
      @discard_pile += @treasures_in_play
      @treasures_in_play = []
      
      @hand.each { |card| card.on_cleanup }
      @discard_pile += @hand
      @hand = []
      
      draw 5
      move_to_phase :setup
      check_for_game_over
      move_to_next_player if in_progress?
    end
    
    def add_actions(actions)
      @actions_available += actions
    end
    
    def add_coins(coins)
      @coins_available += coins
    end
    
    def add_buys(buys)
      @buys_available += buys
    end

    def add_vp_tokens(vp)
      @vp_tokens += vp
    end
    
    def add_pirate_ship_token
      @pirate_ship_tokens += 1
    end
    
    def draw(count = 1)
      (1..count).select { draw_one }
    end
    
    def draw_one
      if @deck.empty?
        @deck = @discard_pile
        @discard_pile = []
        @deck.shuffle!
      end
      card = @deck.pop
      @hand << card if card
      card
    end
    
    def play(card)
      if is_card_class(card)
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
      raise "#{card} is an action card, and there are no actions available" if card.action? && actions_available <= 0
      
      move_to_phase :treasure if action_phase? && card.treasure?   # automatically move to treasure phase
      raise "#{card} is a treasure card, but currently in #{phase} phase" if card.treasure? && !treasure_phase?

      hand.delete card
      
      if action_phase? && card.action?
        @actions_available -= 1
        draw card.cards
        add_actions card.actions
        add_coins card.coins
        add_buys card.buys
        card.play_action
        @actions_in_play << card
      elsif treasure_phase? && card.treasure?
        add_coins card.coins
        add_buys card.buys
        card.play_treasure
        @treasures_in_play << card
      end
      
      card
    end
    
    def play_all_treasures
      treasure_cards = hand.find_all { |card| card.treasure? }
      treasure_cards.each { |card| play card }
    end
    
    def gain(card_class, options = {})
      to = options[:to] || :discard
      
      card = draw_from_supply(card_class, self)
      if card
        card.on_gain
        case to
        when :discard
          @discard_pile << card
        when :deck
          @deck << card
        when :hand
          @hand << card
        end
      end
      
      card
    end
    
    def buy(card_class)
      move_to_phase :buy if action_phase? || treasure_phase?  # automatically move to buy phase

      raise "No more buys available" unless @buys_available > 0
      
      card = peek_from_supply(card_class)
      validate_buy(card)
      
      card = gain(card_class)
      card.on_buy
      @coins_available -= card.cost
      @buys_available -= 1
      
      card
    end
    
    def validate_buy(card)
      raise "#{card} costs $#{card.cost} but only $#{@coins_available} available" if card.cost > @coins_available

      orig_player = card.player
      begin
        card.player = self
        card.validate_buy
      ensure
        card.player = orig_player
      end
    end
    
    def cards_in_play
      actions_in_play + treasures_in_play + durations_on_first_turn + durations_on_second_turn
    end
    
    def all_cards
      deck + discard_pile + hand + cards_in_play
    end
    
    def total_victory_points
      vp_from_cards = all_cards.inject(0) { |sum, card| sum + card.vp }
      vp_from_cards + vp_tokens
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
    
    private
    
    def is_card_class(card)
      card.is_a?(Class) && card.ancestors.include?(Card)
    end
    
  end
end
