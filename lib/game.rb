module Dominion
  class Game

    PHASES = [:prepare, :setup, :action, :treasure, :buy, :cleanup]

    def initialize(options = {})
      @kingdom_cards = []
      @colony_game = false
      @players = []
      @current_player = nil
      @phase = :prepare
      @supply = {}
      
      prepare(options) unless options[:no_prepare]
    end
    
    def prepare(options = {})
      # Create players, then prepare supply, because supply depends on number of players
      # Then prepare the initial decks/hands for the players, drawing from the supply
      @phase = :prepare
      create_players options
      prepare_supply options
      prepare_players options
      @phase = :setup
    end
    
    attr_reader :kingdom_cards, :players, :current_player, :supply
    attr_accessor :phase
    
    def all_cards
      base_cards + kingdom_cards
    end
    
    def base_cards
      base_treasure_cards + base_victory_cards + [Curse]
    end
    
    def base_treasure_cards
      cards = [Copper, Silver, Gold]
      cards.push Platinum if colony_game?
      cards.push Potion if kingdom_cards.any? {|c| c.potion }
      cards
    end
    
    def base_victory_cards
      cards = [Estate, Duchy, Province]
      cards.push Colony if colony_game?
      cards
    end
    
    def colony_game?
      @colony_game
    end
    
    def in_progress?
      @phase != :prepare
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
    
    def num_players
      @players.length
    end
    
    def other_players
      @players.reject { |p| p == current_player }
    end
    
    def draw_from_supply(card, player = nil)
      raise "No cards of type #{card} available in supply" unless @supply[card]
      raise "No more cards of type #{card} available in supply" if @supply[card].empty?
      raise "Player is not playing this game!" if player && player.game != self
      
      result = @supply[card].shift
      result.player = player
      result
    end
    
    private
    
    def create_players(options)
      player_identities = options[:players]
      unless player_identities
        num_players = options[:num_players] || 2
        player_identities = Array.new num_players   # no identities
      end
      
      @players = []
      player_identities.each_with_index do |player_identity, position|
        @players.push Player.new(self, position, player_identity)
      end
      
      @current_player = @players.first
    end
    
    def prepare_players(options)
      @players.each do |player|
        player.prepare options
      end
    end
    
    def prepare_supply(options)
      @kingdom_cards = options[:kingdom_cards] || Preparation.randomly_choose_kingdom(options)
      @colony_game = options[:colony_game?] || Preparation.randomly_choose_if_colony_game(@kingdom_cards)
      
      @supply = {}
      @supply.extend PileSummary  # better to_s for supply
      
      all_cards.each do |card|
        count = Preparation.initial_count_in_supply card, num_players
        pile = (1..count).collect { card.new self }
        @supply[card] = pile
      end
    end

  end
  
  # Is this not sick?  It makes the supply hash to_s display a count, rather than exploding the array
  module PileSummary
    def piles
      inject({}) {|h,v| h[v[0]] = v[1].size; h }
    end
      
    def inspect
      piles
    end
  end
  
end
