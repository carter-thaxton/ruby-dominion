module Dominion
  class Game

    PHASES = [:prepare, :setup, :action, :treasure, :buy, :cleanup, :game_over]

    def initialize(options = {})
      @kingdom_cards = []
      @colony_game = false
      @players = []
      @current_player = nil
      @phase = :prepare
      @supply = {}
      @trash_pile = []

      prepare(options) unless options[:no_prepare]
    end

    def prepare(options = {})
      # Create players, then prepare supply, because supply depends on number of players
      # Then prepare the initial decks/hands for the players, drawing from the supply
      move_to_phase :prepare
      create_players options
      prepare_supply options
      prepare_players options

      move_to_phase :setup
      current_player.start_turn
    end
    
    attr_reader :phase, :kingdom_cards, :players, :current_player, :supply, :trash_pile
    
    def move_to_phase(phase)
      @phase = phase
    end
    
    def all_cards
      base_cards + kingdom_cards
    end
    
    def base_cards
      base_treasure_cards + base_victory_cards + [Curse]
    end
    
    def base_treasure_cards
      cards = [Copper, Silver, Gold]
      cards << Platinum if colony_game?
      cards << Potion if kingdom_cards.any? {|c| c.potion }
      cards
    end
    
    def base_victory_cards
      cards = [Estate, Duchy, Province]
      cards << Colony if colony_game?
      cards
    end
    
    def colony_game?
      @colony_game
    end
    
    def in_progress?
      !prepare_phase? && !game_over?
    end
    
    def prepare_phase?
      @phase == :prepare
    end
    
    def setup_phase?
      @phase == :setup
    end
    
    def action_phase?
      @phase == :action
    end
    
    def treasure_phase?
      @phase == :treasure
    end
    
    def buy_phase?
      @phase == :buy
    end
    
    def cleanup_phase?
      @phase == :cleanup
    end
    
    def game_over?
      @phase == :game_over
    end
    
    def num_players
      @players.length
    end

    def other_players
      # Go around clockwise, starting with next player
      @players.rotate(current_player.position + 1).take(num_players - 1)
    end

    def attacked_players
      other_players.reject &:attack_prevented
    end
    
    def player_to_left
      player_to_left_of current_player
    end
    
    def player_to_left_of(player)
      players[player.position - 1 % num_players]
    end
    
    def supply_counts
      # counts instead of actual instances
      supply.inject({}) {|h,v| h[v[0]] = v[1].count; h }
    end

    def peek_from_supply(card_class)
      pile = @supply[card_class]
      pile && pile.first
    end
    
    def draw_from_supply(card_class, player = nil)
      raise "Player is not playing this game!" if player && player.game != self
      raise "No cards of type #{card_class} available in supply" unless @supply[card_class]

      return nil if @supply[card_class].empty?

      result = @supply[card_class].shift
      result.player = player
      result
    end
    
    def check_for_game_over
      provinces_gone = supply[Province].empty?
      colonies_gone = (colony_game? && supply[Colony].empty?)
      num_empty_piles = supply.count{ |pile| pile.empty? }
      
      game_over = provinces_gone || colonies_gone || num_empty_piles >= 3
      
      if game_over
        move_to_phase :game_over
        @current_player = nil
      end

      game_over
    end
    
    def winner
      # needs work, to handle ties and multiple players
      players.max_by { |player| [player.total_victory_points, -player.turn] }
    end
    
    def move_to_next_player
      raise "Cannot move to next player unless in setup phase" unless setup_phase?
      raise "There are no players" if players.empty?
      
      next_player_position = (current_player.position + 1) % num_players
      player = players[next_player_position]
      
      @current_player = player
      player.start_turn

      player
    end

    def log(message)
      #puts message
    end
    
    private
    
    def create_players(options)
      player_identities = options[:players]
      unless player_identities
        num_players = options.fetch :num_players, 2
        player_identities = Array.new num_players   # no identities
      end
      
      @players = []
      player_identities.each_with_index do |player_identity, position|
        player_strategy = prepare_player_strategy position, options
        @players << Player.new(self, position, player_identity, player_strategy)
      end
      
      @current_player = @players.first
    end

    def prepare_player_strategy(position, options)
      strategies = options.fetch :strategies, []
      strategy = strategies[position] || options[:strategy]
      strategy
    end
    
    def prepare_players(options)
      @players.each do |player|
        player.prepare options
      end
    end
    
    def prepare_supply(options)
      @kingdom_cards = options.fetch :kingdom_cards, Preparation.randomly_choose_kingdom(options)
      @colony_game = options.fetch :colony_game?, Preparation.randomly_choose_if_colony_game(@kingdom_cards, options)
      
      @supply = {}
      all_cards.each do |card|
        count = Preparation.initial_count_in_supply card, num_players
        pile = (1..count).collect { card.new self }
        @supply[card] = pile
      end
    end

  end
  
end
