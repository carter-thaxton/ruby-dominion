module Dominion
  class Game
    PHASES = [:setup, :action, :buy, :cleanup]
    
    def initialize(options = {})
      @kingdom_cards = options[:kingdom_cards] || get_random_kingdom(options)
      
      @players = options[:players]
      if @players
        num_players = @players.length
      else
        num_players = options[:num_players] || 2
        for i in [1..num_players]
          @players.push Player.new
        end
      end
      
      @current_player = @players.first
      @phase = :setup
    end
    
    def self.get_random_kingdom(options = {})
      [Chancellor, Vilage, Bureaucrat, Peddler]
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
