require 'util'

module Dominion
  
  class Player
    include Util
    
    attr_accessor :identity, :strategy, :attack_prevented
    
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
    
    def cards_in_play
      actions_in_play + treasures_in_play + durations_on_first_turn + durations_on_second_turn
      # TODO: set_aside
    end
    
    def all_cards
      deck + discard_pile + hand + cards_in_play
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
      
      @discard_pile += @actions_in_play
      @actions_in_play = []

      @discard_pile += @treasures_in_play
      @treasures_in_play = []

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
      raise "#{card} is not a card in hand" unless hand.include? card
      
      raise "#{card} is not playable" unless card.action? || card.treasure?
      raise "#{card} is an action card, but currently in #{phase} phase" if card.action? && !action_phase?
      raise "#{card} is an action card, but there are no more actions available" if card.action? && actions_available <= 0
      
      move_to_phase :treasure if action_phase? && card.treasure?   # automatically move to treasure phase
      raise "#{card} is a treasure card, but currently in #{phase} phase" if card.treasure? && !treasure_phase?

      hand.delete card
      @card_in_play = card
      @play_choice = options[:choice]

      if card.attack?
        other_players.each do |player|
          player.react_to_attack
        end
      end

      if card.action?
        @actions_in_play << card
        @actions_available -= 1
        draw card.cards
        add_actions card.actions
        add_coins card.coins
        add_buys card.buys
      elsif card.treasure?
        @treasures_in_play << card
        add_coins card.coins
        add_buys card.buys
      end

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
    
    def trash(card_or_class)
      return if card_or_class.nil?
      card = resolve_card_or_class(card_or_class)
      if card
        # TODO: prevent double-trashing for Throne Room / Feast
        hand.delete card
        game.trash_pile << card
      end
      card
    end

    def put_on_deck(card_or_class)
      return if card_or_class.nil?
      card = resolve_card_or_class(card_or_class)
      if card
        hand.delete card
        deck.unshift card
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
        cards_or_classes.each do |card_or_class|
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
      hand.dup.each do |card|
        discard card
      end
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
          card.on_gain
          # TODO: handle gains that place this card somewhere else
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
    
    def ask(message, options = {})
      options[:message] = message
      options[:type] = :bool
      options[:multiple] = false
      choose(options)
    end
    
    def choose_card(message, options = {})
      options[:message] = message
      options[:type] = :card
      options[:multiple] = false
      choose(options)
    end
    
    def choose_cards(message, options = {})
      options[:message] = message
      options[:type] = :card
      options[:multiple] = true
      choose(options)
    end

    def choose_one(messages, symbols, options = {})
      if symbols.count > 1
        options[:message] = 'Choose one: ' + messages.join(' or ')
        options[:messages] = messages
        options[:type] = :symbol
        options[:multiple] = false
        options[:restrict_to] = symbols
        choose(options)
      else
        # Don't bother asking for zero or one choices
        symbols.first
      end
    end

    def choose(options)
      @choice_in_progress = options

      # use choice if given directly in call to play
      # otherwise defer to strategy if available
      response = if @play_choice
        handle_response(@play_choice)
      elsif @strategy
        handle_response(@strategy.choose(self, options))
      else
        nil
      end

      @choice_in_progress = nil
      response
    end
    
    def reveal_from_hand(card_or_class_or_type)
      card = find_card_in_hand(card_or_class_or_type)
      if card
        if options[:required]
          reveal card
        else
          if ask "Reveal #{card}?"
            reveal card
          end
        end
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
      if card_or_class_or_type.is_a? Card
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
        raise "Invalid card_or_class_or_type to find_card_in_hand: #{card_or_class}"
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
      durations_on_second_turn.each do |card|
        card.on_attack
      end
      hand.each do |card|
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
      raise "Cannot play while choice in progress" if @choice_in_progress
    end

    def resolve_card_or_class(card_or_class)
      result = if card_or_class.is_a? Card
        card_or_class
      else
        find_card_in_hand card_or_class, :required => true
      end
      result
    end
    
    def handle_response(response)
      raise "Cannot handle response unless waiting for choice" unless @choice_in_progress

      multiple = @choice_in_progress[:multiple]
      type = @choice_in_progress[:type]
      from = @choice_in_progress[:from]
      max = @choice_in_progress[:max]
      min = @choice_in_progress[:min]
      count = @choice_in_progress[:count]
      restrict_to = @choice_in_progress[:restrict_to]
      max_cost = @choice_in_progress[:max_cost]
      card_type = @choice_in_progress[:card_type]

      if count
        min = max = count
      end

      if multiple
        response = [response] unless response.is_a? Enumerable
      end
      
      # common operation of finding cards in hand by type
      if type == :card
        if from == :hand
          if multiple
            response = find_cards_in_hand(response)
          else
            response = find_card_in_hand(response)
          end
        elsif from == :supply
          raise "Cannot choose multiple cards from supply" if multiple
          response = peek_from_supply(response)
        else
          raise "Cards must be chosen from hand or supply"
        end
      end

      if type == :bool
        if multiple
          response.each do |r|
            raise "Response must be an array of true or false values" unless r == true or r == false
          end
        else
          raise "Response must be true or false" unless response == true or response == false
        end
      end

      if restrict_to
        if multiple
          response.each do |r|
            raise "Response must be an array of one of: " + restrict_to.to_s unless restrict_to.include?(r)
          end
        elsif type == :card
          raise "Response must be one of: " + restrict_to.to_s unless restrict_to.include?(response.card_class)
        else
          raise "Response must be one of: " + restrict_to.to_s unless restrict_to.include?(response)
        end
      end

      if type == :card && max_cost
        raise "Card must cost no more than #{max_cost}, but #{response} costs #{response.cost}" if response.cost > max_cost
      end

      if type == :card && card_type
        raise "Card must have type #{card_type}, but #{response} has type #{response.type}" unless response.type.include?(card_type)
      end

      if multiple && max
        raise "At most #{max} may be chosen" if response.size > max
      end

      if multiple && min
        raise "At least #{min} must be chosen" if response.size < min
      end

      response
    end

  end
end
