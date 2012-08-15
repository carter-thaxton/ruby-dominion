require 'util'
require 'set'
require 'choices'

module Dominion
  
  class Player
    include Util
    include Choices
    
    attr_accessor :identity, :strategy, :attack_prevented
    
    attr_reader :game, :position,
      :deck, :discard_pile, :hand,
      :actions_in_play, :treasures_in_play,
      :actions_in_play_from_previous_turn,
      :actions_available, :coins_available, :buys_available,
      :actions_played, :vp_tokens, :pirate_ship_tokens,
      :turn, :card_in_play
    
    def initialize(game, position, identity, strategy)
      @game = game
      @position = position
      @identity = identity
      @strategy = strategy
      @deck = []
      @discard_pile = []
      @hand = []
      @actions_in_play = Set.new
      @treasures_in_play = Set.new
      @actions_in_play_from_previous_turn = Set.new
      @actions_available = 0
      @coins_available = 0
      @buys_available = 0
      @vp_tokens = 0
      @actions_played = 0
      @pirate_ship_tokens = 0
      @turn = 0
      @card_in_play = nil
      @attack_prevented = false
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

    def current_player?
      game.current_player == self
    end
    
    def player_to_left
      game.player_to_left_of self
    end
    
    def cards_in_play
      actions_in_play + treasures_in_play + actions_in_play_from_previous_turn
    end
    
    def all_cards
      cards_in_play + deck + discard_pile + hand
      # TODO: mats
    end
    
    def total_victory_points
      vp_from_cards = all_cards.inject(0) { |sum, card| sum + card.vp }
      vp_from_cards + vp_tokens
    end

    def total_treasure
      all_cards.inject(0) { |sum, card| sum + card.coins }
    end

    def start_turn
      check_turn
      raise "Cannot start turn in #{phase} phase" unless setup_phase?

      @turn += 1
      @actions_played = 0
      @actions_available = 1
      @coins_available = 0
      @buys_available = 1

      # Play duration cards again, accounting for Throne Room and King's Court
      @actions_in_play_from_previous_turn.each do |card|
        if card.played_by
          card.played_by.multiplier.times do
            card.on_setup_after_duration
          end
        else
          card.on_setup_after_duration
        end
      end

      move_to_phase :action
    end

    def end_turn
      check_turn
      raise "Cannot end turn in #{phase} phase" unless action_phase? || treasure_phase? || buy_phase?
      raise "Cannot end turn while choice in progress" if choice_in_progress

      move_to_phase :cleanup

      # keep durations and any Throne Rooms or King's Courts that directly played those durations
      actions_to_keep = Set.new
      @actions_in_play.each do |card|
        if card.duration?
          actions_to_keep << card
          actions_to_keep << card.played_by if card.played_by && card.played_by.multiplier > 1
        end
      end

      actions_to_discard = @actions_in_play - actions_to_keep
      to_discard = actions_to_discard.to_a + @treasures_in_play.to_a + @actions_in_play_from_previous_turn.to_a

      to_discard.each do |c|
        c.on_cleanup
        c.played_by = nil
      end

      @discard_pile += to_discard
      @actions_in_play_from_previous_turn = Set.new(actions_to_keep)
      @actions_in_play = Set.new
      @treasures_in_play = Set.new

      @discard_pile += @hand
      @hand = []

      # TODO: handle Outpost

      check_for_game_over
      if in_progress?
        draw 5
        move_to_phase :setup
        move_to_next_player
      end
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
      (1..count).select { draw_to_hand }
    end
    
    def draw_to_hand
      card = draw_from_deck
      put_in_hand card
      card
    end

    def draw_from_deck
      if @deck.empty?
        @deck = @discard_pile
        @discard_pile = []
        @deck.shuffle!
      end
      @deck.pop
    end

    def play(card_or_class, options = {})
      check_turn
      card = resolve_card_or_class(card_or_class)

      raise "#{card} is not a valid card" unless card.is_a? Card
      raise "#{card} is not the player's own card!" unless card.player == self
      raise "#{card} is not a card in hand" unless hand.include?(card) || options[:played_by_card]
      
      raise "#{card} is not playable" unless card.action? || card.treasure?
      raise "#{card} is an action card, but currently in #{phase} phase" if card.action? && !action_phase?
      raise "#{card} is an action card, but there are no more actions available" if card.action? && actions_available <= 0 unless options[:played_by_card]
      
      move_to_phase :treasure if action_phase? && card.treasure?   # automatically move to treasure phase
      raise "#{card} is a treasure card, but currently in #{phase} phase" if card.treasure? && !treasure_phase?

      hand.delete card
      @card_in_play = card
      @play_choice = options[:choice]
      card.played_by = options[:played_by_card]

      if card.attack?
        other_players.each do |player|
          player.react_to_attack
        end
      end

      if card.action?
        @actions_in_play << card
        @actions_available -= 1 unless options[:played_by_card]
        @actions_played += 1
      elsif card.treasure?
        @treasures_in_play << card
      end

      draw card.cards
      add_actions card.actions
      add_coins card.coins
      add_buys card.buys

      card.on_play

      @card_in_play = nil
      @play_choice = nil

      players.each do |player|
        player.attack_prevented = false
      end

      card
    end

    def play_all_treasures
      check_turn
      treasure_cards = hand.find_all { |card| card.treasure? }
      treasure_cards.each { |card| play card }
    end
    
    def trash(cards_or_classes)
      return if cards_or_classes.nil?
      if cards_or_classes.is_a?(Enumerable)
        cards_or_classes.dup.each do |card_or_class|
          trash(card_or_class)
        end
      else
        card = resolve_card_or_class(cards_or_classes)
        if card
          # Delete instance from the various places cards can be
          hand.delete card
          actions_in_play.delete card
          treasures_in_play.delete card

          # Add to trash it unless it's already there (e.g. Throne Room + Feast)
          game.trash_pile << card unless game.trash_pile.include?(card)
        end
        card
      end
    end

    def put_on_deck(card_or_class)
      return if card_or_class.nil?
      card = resolve_card_or_class(card_or_class)
      if card
        hand.delete card
        deck << card
      end
      card
    end

    def put_in_hand(cards)
      return if cards.nil?
      cards = [cards] unless cards.is_a?(Enumerable)
      cards.each do |card|
        @hand << card
      end
    end

    def discard(cards_or_classes)
      return if cards_or_classes.nil?
      if cards_or_classes.is_a? Enumerable
        cards_or_classes.dup.each do |card_or_class|
          discard card_or_class
        end
      else
        card = resolve_card_or_class(cards_or_classes)
        if card
          card.on_discard
          hand.delete card
          discard_pile << card
        end
        card
      end
    end

    def discard_hand
      discard hand
    end
    
    def gain(cards_or_classes, options = {})
      return if cards_or_classes.nil?
      if cards_or_classes.is_a?(Enumerable)
        # Loop in reverse, so first goes on top of deck or discard
        cards_or_classes.reverse.each do |card_or_class|
          gain(card_or_class, options)
        end
      else
        card_class = cards_or_classes.card_class
        to = options.fetch :to, :discard
        card = draw_from_supply(card_class, self)
        if card
          # TODO: handle gains that place this card somewhere else, or that gain something else instead
          card.on_gain

          # Hook for any card gained
          all_players_cards do |c|
            c.on_any_card_gained(card, self)
          end

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
    end
    
    def buy(card_or_class)
      return if card_or_class.nil?
      check_turn
      card_class = card_or_class.card_class
      can_buy card_class, :throw_exception => true

      move_to_phase :buy if action_phase? || treasure_phase?  # automatically move to buy phase
      
      card = gain(card_class)
      card.on_buy

      # Hook for any card bought
      all_players_cards do |c|
        c.on_any_card_bought(card, self)
      end

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
    
    def reveal_cards_from_deck(num_cards)
      cards = []
      num_cards.times do
        card = draw_from_deck
        cards << card if card
      end
      reveal cards
    end

    def reveal_from_hand(card_or_class_or_type, options = {})
      card = find_card_in_hand(card_or_class_or_type)
      if card
        if options[:required]
          reveal card
        else
          if ask "Reveal #{card}?"
            reveal card
          end
        end
      elsif options[:required]
        reveal hand
        nil
      end
    end

    def reveal(card)
      if card.is_a?(Enumerable)
        log "#{self} reveals #{card.join(', ')}"
      else
        log "#{self} reveals a #{card}"
      end
      card
    end

    def find_card_in_hand(card_or_class_or_type, options = {})
      hand = options.fetch :hand, self.hand
      if card_or_class_or_type.nil?
        nil
      elsif card_or_class_or_type.is_a? Card
        card = card_or_class_or_type
        raise "#{card} is not in the player's hand" unless hand.include?(card)
      elsif is_card_class(card_or_class_or_type)
        # choose an instance from the player's hand of the given class
        card_class = card_or_class_or_type
        card = hand.find {|card| card.is_a? card_class}
        if options[:required]
          raise "No #{card_class} card found in hand" unless card
        end
      elsif card_or_class_or_type.is_a? Symbol
        type = card_or_class_or_type
        card = hand.find {|card| card.type == type}
        if options[:required]
          raise "No #{type} card found in hand" unless card
        end
      else
        raise "Invalid card_or_class_or_type to find_card_in_hand: #{card_or_class_or_type}"
      end
      card
    end

    def find_cards_in_hand(cards_or_classes, options = {})
      tmp_hand = hand.dup
      options[:hand] = tmp_hand
      
      cards_or_classes.collect do |card_or_class|
        card = find_card_in_hand(card_or_class, options)
        tmp_hand.delete card if card
        card
      end
    end

    def react_to_attack
      cards_in_play.dup.each do |card|
        card.on_attack
      end
      hand.dup.each do |card|
        card.on_attack
      end
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
      raise "It is not #{name}'s turn" unless current_player?
      raise "Cannot play while choice in progress" if choice_in_progress
    end

    def resolve_card_or_class(card_or_class)
      result = if card_or_class.is_a? Card
        card_or_class
      else
        find_card_in_hand card_or_class, :required => true
      end
      result
    end
    
  end
end
