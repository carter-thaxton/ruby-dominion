require 'util'

module Dominion
  
  class Player
    include Util
    
    attr_accessor :identity, :strategy
    
    attr_reader :game, :position,
      :deck, :discard_pile, :hand,
      :actions_in_play, :treasures_in_play,
      :durations_on_first_turn, :durations_on_second_turn,
      :actions_available, :coins_available, :buys_available,
      :vp_tokens, :pirate_ship_tokens,
      :turn, :card_in_play, :choice_in_progress
    
    def initialize(game, position, identity, strategy)
      @game = game
      @position = position
      @identity = identity
      @strategy = strategy
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
      @card_in_play = nil
      @choice_in_progress = nil
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
      check_turn
      
      raise "Cannot end turn in #{phase} phase" unless action_phase? || treasure_phase? || buy_phase?
      raise "Cannot end turn while choice in progress" if @choice_in_progress
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
    
    def play(card, options = {})
      check_turn
      
      card = find_card_in_hand card, :required => true

      raise "#{card} is not a valid card" unless card.is_a? Card
      raise "#{card} is not the player's own card!" unless card.player == self
      raise "#{card} is not a card in hand" unless hand.include? card
      
      raise "#{card} is not playable" unless card.action? || card.treasure?
      raise "#{card} is an action card, but currently in #{phase} phase" if card.action? && !action_phase?
      raise "#{card} is an action card, and there are no more actions available" if card.action? && actions_available <= 0
      
      move_to_phase :treasure if action_phase? && card.treasure?   # automatically move to treasure phase
      raise "#{card} is a treasure card, but currently in #{phase} phase" if card.treasure? && !treasure_phase?

      hand.delete card
      @card_in_play = card
      @play_choice = options[:choice]
      
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
      
      @card_in_play = nil
      @play_choice = nil
      card
    end
    
    def play_all_treasures
      check_turn
      treasure_cards = hand.find_all { |card| card.treasure? }
      treasure_cards.each { |card| play card }
    end
    
    def trash(card)
      card = find_card_in_hand card, :required => true
      hand.delete card
      game.trash_pile << card
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
      check_turn
      can_buy card_class, :throw_exception => true
      
      move_to_phase :buy if action_phase? || treasure_phase?  # automatically move to buy phase
      
      card = gain(card_class)
      card.on_buy
      @coins_available -= card.cost
      @buys_available -= 1
      
      card
    end
    
    def can_buy(card_class, options = {})
      throw_exception = options[:throw_exception]
      
      unless buy_phase? || treasure_phase? || action_phase?
        raise "Cannot buy cards in the #{phase} phase" if throw_exception
        return false
      end
      
      unless @buys_available > 0
        raise "No more buys available" if throw_exception
        return false
      end
      
      card = peek_from_supply card_class
      unless card
        raise "#{card_class} not available in supply" if throw_exception
        return false
      end
      
      if card.cost > @coins_available
        raise "#{card} costs $#{card.cost} but only $#{@coins_available} available" if throw_exception
        return false
      end

      orig_player = card.player
      begin
        card.player = self
        return card.can_buy
      ensure
        card.player = orig_player
      end
    end
    
    def ask(message, options = {}, &block)
      options[:message] = message
      options[:type] = :bool
      options[:multiple] = false
      choose(options, &block)
    end
    
    def choose_card(message, options = {}, &block)
      options[:message] = message
      options[:type] = :card
      options[:multiple] = false
      choose(options, &block)
    end
    
    def choose_cards(message, options = {}, &block)
      options[:message] = message
      options[:type] = :card
      options[:multiple] = true
      choose(options, &block)
    end
    
    def choose(options, &block)
      @resume_block = block
      @choice_in_progress = options
      
      # use choice if given in call to play
      # otherwise defer to strategy if available
      if @play_choice
        respond(@play_choice)
      elsif @strategy
        @strategy.choose self, @card_in_play, options
      else
        # useful in console when no choice or strategy
        puts options[:message]
      end
    end
    
    def respond(response)
      raise "Cannot respond unless waiting for choice" unless @choice_in_progress
      response = handle_response(response)
      
      @resume_block.call(response)
      @resume_block = nil
      @choice_in_progress = nil
      response
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
    
    def total_treasure
      all_cards.inject(0) { |sum, card| sum + card.coins }
    end
    
    def name
      if identity.nil?
        "Player #{position + 1}"
      else
        identity.to_s
      end
    end
    
    def to_s
      name
    end
    
    private

    def method_missing(method, *args, &block)
      @game.send method, *args, &block
    end
    
    def check_turn
      raise "It is not #{name}'s turn" unless game.current_player == self
      raise "Cannot play while choice in progress" if @choice_in_progress
    end
    
    def handle_response(response)
      if @choice_in_progress[:multiple]
        response = [response] unless response.is_a? Enumerable
      end
      
      # common operation of finding cards in hand by type
      if @choice_in_progress[:from] == :hand
        if @choice_in_progress[:type] == :card
          if @choice_in_progress[:multiple]
            return find_cards_in_hand(response)
          else
            return find_card_in_hand(response)
          end
        end
      end
      
      if @choice_in_progress[:multiple] && @choice_in_progress[:max]
        raise "At most #{@choice_in_progress[:max]} may be chosen" if response.size > @choice_in_progress[:max]
      end
      
      if @choice_in_progress[:multiple] && @choice_in_progress[:min]
        raise "At least #{@choice_in_progress[:min]} must be chosen" if response.size < @choice_in_progress[:min]
      end

      response
    end
    
    def find_card_in_hand(card, options = {})
      set = options[:set] || hand
      if card.is_a? Card
        raise "#{card} is not in the player's hand" unless set.include?(card)
      elsif is_card_class(card)
        # choose an instance from the player's hand of the given class
        card_class = card
        card = set.find {|card| card.is_a? card_class}
        if options[:required]
          raise "No card of type #{card_class} found in hand" unless card
        end
      end
      card
    end

    def find_cards_in_hand(cards, options = {})
      tmp_hand = hand.dup
      options[:set] = tmp_hand
      
      cards.collect do |card|
        card = find_card_in_hand(card, options)
        tmp_hand.delete card if card
        card
      end
    end
    
  end
end
