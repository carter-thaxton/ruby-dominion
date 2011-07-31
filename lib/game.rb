module Dominion
  class Game
    PHASES = [:none, :setup, :action, :buy, :cleanup]

    # Game context used for cards when unassociated with a context
    BASE_CONTEXT = Game.new
    
    def initialize(options = nil)
      @kingdom_cards = []
      @colony_game = false
      @players = []
      @current_player = nil
      @phase = :none
      
      setup(options) if options
    end
    
    def setup(options = {})
      @kingdom_cards = options[:kingdom_cards] || Kingdom.randomly_choose_kingdom(options)
      @colony_game = options[:colony_game?] || Kingdom.randomly_choose_if_colony_game(@kingdom_cards)
      
      player_identities = options[:players]
      if player_identities
        num_players = player_identities.length
      else
        num_players = options[:num_players] || 2
      end
      
      @players = []
      if player_identities
        player_identities.each do |player_identity|
          @players.push Player.new(player_identity)
        end
      else
        num_players.times do
          @players.push Player.new
        end
      end
      
      @current_player = @players.first
      @phase = :setup
    end
    
    def colony_game?
      @colony_game
    end
    
    def all_cards
      base_cards + kingdom_cards
    end
    
    def base_cards
      cards = [Copper, Silver, Gold, Estate, Duchy, Province, Curse]
      cards += [Platinum, Colony] if colony_game?
      cards.push Potion if kingdom_cards.any? {|c| c.potion }
      cards
    end
    
    def kingdom_cards
      @kingdom_cards
    end
    
    def in_progress?
      @phase != :none
    end
    
    def setup_phase?
      @phase == :setup
    end
    
    def action_phase?
      @phase == :action
    end
    
    def buy_phase?
      @phase == :buy
    end
    
    def cleanup_phase?
      @phase == :cleanup
    end
    
    def players
      @players
    end
    
    def num_players
      @players.length
    end
    
    def current_player
      @current_player
    end
    
    def other_players
      @players.reject { |p| p == current_player }
    end
    
  end
end
