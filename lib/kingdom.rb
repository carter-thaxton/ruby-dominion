require 'cards'

module Dominion
  class Kingdom
    def self.randomly_choose_kingdom(options = {})
      [Chancellor, Village, Bureaucrat, Peddler, Familiar]
    end
    
    def self.randomly_choose_if_colony_game(kingdom_cards, options = {})
      true
    end
  end
end
