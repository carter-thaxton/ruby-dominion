require 'card'

module Dominion
  
  #
  # Base cards
  #

  # Copper, Silver, Gold, Platinum, Potion
  # Estate, Duchy, Province, Colony
  # Curse
  
  class Copper < Card
    type :base, :treasure
    cost 0
    coins 1
  end

  class Silver < Card
    type :base, :treasure
    cost 3
    coins 2
  end

  class Gold < Card
    type :base, :treasure
    cost 6
    coins 3
  end

  class Platinum < Card
    type :base, :treasure
    cost 9
    coins 5
  end
  
  class Potion < Card
    type :base, :treasure
    cost 4
  end

  class Estate < Card
    type :base, :victory
    cost 2
    vp 1
  end

  class Duchy < Card
    type :base, :victory
    cost 5
    vp 3
  end

  class Province < Card
    type :base, :victory
    cost 8
    vp 6
  end

  class Colony < Card
    type :base, :victory
    cost 11
    vp 10
  end

  class Curse < Card
    type :base, :curse
    cost 0
    vp -1
  end


  #
  # Dominion (Base Game)
  #
  
  class Cellar < Card
  end
  
  class Chapel < Card
    type :action
    cost 2
    
    def play_action
      choose_cards "Choose up to 4 cards to trash", :from => :hand, :max => 4 do |cards|
        cards.each do |card|
          trash card
        end
      end
    end
  end
  
  class Moat < Card
  end
  
  class Chancellor < Card
    type :action
    cost 3
    coins 2
    
    def play_action
      ask "Immediately put deck into discard pile?" do |discard_deck|
        if discard_deck
          discard_pile.concat deck
          deck.clear
        end
      end
    end
  end

  class Village < Card
    type :action
    cost 3
    cards 1
    actions 2
  end
  
  class Woodcutter < Card
    type :action
    cost 3
    coins 2
    buys 1
  end
  
  class Workshop < Card
  end
  
  class Bureaucrat < Card
    type :action, :attack
    cost 3
    coins 2

    def play_action
      gain Silver, :to => :deck
      other_players.each do |player|
        player.reveal :type => :victory, :attack => true do |card|
          player.put card, :to => :deck if card
        end
      end
    end
  end

  class Feast < Card
  end
  
  class Gardens < Card
  end
  
  class Militia < Card
  end
  
  class Moneylender < Card
    type :action
    cost 4
    
    def play_action
      copper = hand.find {|card| card.is_a? Copper}
      if copper
        trash copper
        add_coins 3
      end
    end
  end
  
  class Remodel < Card
  end
  
  class Smithy < Card
    type :action
    cost 4
    cards 3
  end

  class Spy < Card
  end
  
  class Thief < Card
  end
  
  class ThroneRoom < Card
  end
  
  class CouncilRoom < Card
    type :action
    cost 5
    cards 4
    buys 1
    
    def play_action
      other_players.each do |player|
        player.draw_one
      end
    end
  end
  
  class Festival < Card
    type :action
    cost 5
    actions 2
    coins 2
    buys 1
  end
  
  class Laboratory < Card
    type :action
    cost 5
    cards 2
    actions 1
  end
  
  class Library < Card
  end
  
  class Market < Card
    type :action
    cost 5
    cards 1
    actions 1
    coins 1
    buys 1
  end

  class Mine < Card
  end
  
  class Witch < Card
    type :action, :attack
    cost 5
    cards 2
    
    def play_action
      other_players.each do |player|
        player.gain Curse, :attack => true
      end
    end
  end
  
  class Adventurer < Card
  end
  

  #
  # Dominion: Intrigue
  #
  
  class Courtyard < Card
  end
  
  class Pawn < Card
  end
  
  class SecretChamber < Card
  end
  
  class GreatHall < Card
    type :action, :victory
    cost 3
    cards 1
    actions 1
    vp 1
  end
  
  class Masquerade < Card
  end
  
  class ShantyTown < Card
  end
  
  class Steward < Card
  end
  
  class Swindler < Card
  end
  
  class WishingWell < Card
  end
  
  class Baron < Card
  end
  
  class Bridge < Card
  end
  
  class Conspirator < Card
  end
  
  class Coppersmith < Card
  end
  
  class Ironworks < Card
  end
  
  class MiningVillage < Card
  end
  
  class Scout < Card
  end
  
  class Duke < Card
  end
  
  class Minion < Card
  end
  
  class Saboteur < Card
  end
  
  class Torturer < Card
  end
  
  class TradingPost < Card
  end
  
  class Tribute < Card
  end
  
  class Upgrade < Card
  end
  
  class Harem < Card
    type :treasure, :victory
    cost 6
    coins 2
    vp 2
  end
  
  class Nobles < Card
  end
  
  
  #
  # Seaside
  #
  
  class Embargo < Card
  end
  
  class Haven < Card
  end
  
  class Lighthouse < Card
  end
  
  class NativeVillage < Card
  end
  
  class PearlDiver < Card
  end
  
  class Ambassador < Card
  end
  
  class FishingVillage < Card
  end
  
  class Lookout < Card
  end
  
  class Smugglers < Card
  end
  
  class Warehouse < Card
  end
  
  class Caravan < Card
  end
  
  class Cutpurse < Card
  end
  
  class Island < Card
  end
  
  class Navigator < Card
  end
  
  class PirateShip < Card
  end
  
  class Salvager < Card
    type :action
    cost 4
    
    def play_action
      choose_card "Choose a card to trash", :from => :hand do |card|
        if card
          add_coins card.cost
          trash card
        end
      end
    end
  end
  
  class SeaHag < Card
  end
  
  class TreasureMap < Card
  end
  
  class Bazaar < Card
    type :action
    cost 5
    cards 1
    actions 2
    coins 1
  end
  
  class Explorer < Card
  end
  
  class GhostShip < Card
  end
  
  class MerchantShip < Card
  end
  
  class Outpost < Card
  end
  
  class Tactician < Card
  end
  
  class Treasury < Card
  end
  
  class Wharf < Card
  end
  
  
  #
  # Alchemy
  #

  class Herbalist < Card
  end
  
  class Apprentice < Card
  end
  
  class Transmute < Card
  end
  
  class Vineyard < Card
  end
  
  class Apothecary < Card
  end
  
  class ScryingPool < Card
  end
  
  class University < Card
  end
  
  class Alchemist < Card
  end
  
  class Familiar < Card
    type :action, :attack
    cost 3
    potion true
    cards 1
    actions 1
    
    def play_action
      other_players.each do |player|
        player.gain Curse, :attack => true
      end
    end
  end

  class PhilosophersStone < Card
  end
  
  class Golem < Card
  end
  
  class Possession < Card
  end
  
  
  #
  # Prosperity
  #

  class Loan < Card
  end
  
  class TradeRoute < Card
  end
  
  class Watchtower < Card
  end
  
  class Bishop < Card
    type :action
    cost 4
    coins 1

    def play_action
      add_vp_tokens 1
      choose_card "Choose a card to trash", :from => :hand do |card|
        if card
          add_vp_tokens (card.cost / 2).floor
          trash card
        end
      end
    end
  end

  class Monument < Card
    type :action
    cost 4
    coins 2
    
    def play_action
      add_vp_tokens 1
    end
  end
  
  class Quarry < Card
  end
  
  class Talisman < Card
  end
  
  class WorkersVillage < Card
    type :action
    cost 4
    cards 1
    actions 2
    buys 1
  end
  
  class City < Card
  end
  
  class Contraband < Card
  end
  
  class CountingHouse < Card
  end
  
  class Mint < Card
  end
  
  class Mountebank < Card
    type :action, :attack
    cost 5
    coins 2
    
    def play_action
      other_players.each do |player|
        player.reveal :type => Curse, :attack => true do |curse, attack_failed|
          unless attack_failed
            if curse
              player.discard curse
            else
              player.gain Copper
              player.gain Curse
            end
          end
        end
      end
    end
  end
  
  class Rabble < Card
  end
  
  class RoyalSeal < Card
  end
  
  class Vault < Card
  end
  
  class Venture < Card
  end
  
  class Goons < Card
  end
  
  class GrandMarket < Card
    type :action
    cost 6
    cards 1
    actions 1
    coins 2
    buys 1
    
    def can_buy
      !treasures_in_play.any? { |card| card.is_a? Copper }
    end
    
    def on_buy
      raise "Cannot buy GrandMarket when Coppers are in play" unless can_buy
    end
  end

  class Hoard < Card
  end
  
  class Bank < Card
  end
  
  class Expand < Card
  end
  
  class Forge < Card
  end
  
  class KingsCourt < Card
  end
  
  class Peddler < Card
    type :action
    cost :dynamic   # 8* (see below)
    cards 1
    actions 1
    coins 1

    def cost
      if buy_phase?
        num_actions = actions_in_play.size + durations_in_play.size
        [8 - 2 * num_actions, 0].max
      else
        8
      end
    end
  end
  
  
  #
  # Cornucopia
  #

  class Hamlet < Card
  end
  
  class FarmingVillage < Card
  end
  
  class FortuneTeller < Card
  end
  
  class Menagerie < Card
  end
  
  class HorseTraders < Card
  end
  
  class Remake < Card
  end
  
  class Tournament < Card
  end
  
  class YoungWitch < Card
  end
  
  class Harvest < Card
  end
  
  class HornOfPlenty < Card
  end
  
  class HuntingParty < Card
  end
  
  class Jester < Card
  end
  
  class Fairgrounds < Card
    type :victory
    cost 6
    vp :dynamic
    
    def vp
      num_unique_cards = all_cards.map {|c| c.class }.uniq.size
      num_unique_cards * 2
    end
  end

  
  #
  # Promo
  #

  class BlackMarket < Card
    # Good luck...
  end
  
  class Envoy < Card
  end
  
  class Stash < Card
  end
  
end
