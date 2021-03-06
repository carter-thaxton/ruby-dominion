require 'cards'

module Dominion
  module Preparation
    def self.randomly_choose_kingdom(options = {})
      Dominion.all_defined_kingdom_cards.shuffle.take 10
    end
    
    def self.randomly_choose_if_colony_game(kingdom_cards, options = {})
      num_prosperity_cards = kingdom_cards.count { |card| card.set == :prosperity }
      odds = num_prosperity_cards.to_f / kingdom_cards.count
      rand < odds
    end

    def self.randomly_choose_bane_card(kingdom_cards, options = {})
      candidates = Dominion.all_defined_kingdom_cards.select { |card|
        !kingdom_cards.include?(card) && (card.cost == 2 || card.cost == 3) && !card.potion
      }
      candidates.shuffle.first
    end
    
    def self.initial_count_in_supply(card, num_players)
      result = case

      when card == Curse
        case num_players
        when 0, 1, 2
          10
        when 3
          20
        else
          30
        end

      when card.victory?
        case num_players
        when 0, 1, 2
          8
        else
          12
        end

      when card == Copper
        60
      when card == Silver
        40
      when card == Gold
        30
      when card == Platinum
        12
      when card == Potion
        16
      else
        10
      end
      
      # Rules say that the count of Estates in the supply are calculated 'after' dealing the initial cards.
      # Account for that here, by adding 3 extra Estates per player, then drawing cards for players.
      result += 3 * num_players if card == Estate

      result
    end
    
  end
end
