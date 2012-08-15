require 'card'

module Dominion
  
  #
  # Base cards
  #

  # Copper, Silver, Gold, Platinum, Potion
  # Estate, Duchy, Province, Colony
  # Curse
  
  class Copper < Card
    set :base
    type :base, :treasure
    cost 0
    coins 1
  end

  class Silver < Card
    set :base
    type :base, :treasure
    cost 3
    coins 2
  end

  class Gold < Card
    set :base
    type :base, :treasure
    cost 6
    coins 3
  end

  class Platinum < Card
    set :prosperity
    type :base, :treasure
    cost 9
    coins 5
  end
  
  class Potion < Card
    set :alchemy
    type :base, :treasure
    cost 4
  end

  class Estate < Card
    set :base
    type :base, :victory
    cost 2
    vp 1
  end

  class Duchy < Card
    set :base
    type :base, :victory
    cost 5
    vp 3
  end

  class Province < Card
    set :base
    type :base, :victory
    cost 8
    vp 6
  end

  class Colony < Card
    set :prosperity
    type :base, :victory
    cost 11
    vp 10
  end

  class Curse < Card
    set :base
    type :base, :curse
    cost 0
    vp -1
  end


  #
  # Base Game
  #
  
  class Cellar < Card
    set :base
    type :action
    cost 2
    actions 1

    def on_play
      cards = choose_cards "Choose any number of cards to discard", :from => :hand
      discard cards
      draw cards.count
    end
  end
  
  class Chapel < Card
    set :base
    type :action
    cost 2
    
    def on_play
      cards = choose_cards "Choose up to 4 cards to trash", :from => :hand, :max => 4
      trash cards
    end
  end
  
  class Moat < Card
    set :base
    type :action, :reaction
    cost 2
    cards 2

    def on_attack
      if in_hand? && !player.attack_prevented
        if ask "Reveal Moat?"
          player.attack_prevented = true
        end
      end
    end
  end
  
  class Chancellor < Card
    set :base
    type :action
    cost 3
    coins 2
    
    def on_play
      if ask "Immediately put deck into discard pile?"
        discard_pile.concat deck
        deck.clear
      end
    end
  end

  class Village < Card
    set :base
    type :action
    cost 3
    cards 1
    actions 2
  end
  
  class Woodcutter < Card
    set :base
    type :action
    cost 3
    coins 2
    buys 1
  end
  
  class Workshop < Card
    set :base
    type :action
    cost 3

    def on_play
      card = choose_card "Choose a card to gain", :from => :supply, :max_cost => 4, :required => true
      gain card
    end
  end
  
  class Bureaucrat < Card
    set :base
    type :action, :attack
    cost 3
    coins 2

    def on_play
      gain Silver, :to => :deck
      attacked_players.each do |player|
        card = player.reveal_from_hand :victory, :required => true
        player.put card, :to => :deck if card
      end
    end
  end

  class Feast < Card
    set :base
    type :action
    cost 4

    def on_play
      card = choose_card "Choose a card to gain", :from => :supply, :max_cost => 5, :required => true
      gain card
      trash self
    end
  end
  
  class Gardens < Card
    set :base
    type :victory
    cost 4

    def vp
      all_cards.count / 10
    end
  end
  
  class Militia < Card
    set :base
    type :action, :attack
    cost 4
    coins 2

    def on_play
      attacked_players.each do |player|
        hand_size = player.hand.size
        if hand_size > 3
          count = hand_size - 3
          cards = player.choose_cards "Discard #{count} cards", :from => :hand, :count => count
          player.discard cards
        end
      end
    end
  end
  
  class Moneylender < Card
    set :base
    type :action
    cost 4
    
    def on_play
      copper = find_card_in_hand Copper
      if copper
        trash copper
        add_coins 3
      end
    end
  end
  
  class Remodel < Card
    set :base
    type :action
    cost 4

    def on_play
      card = choose_card "Choose a card to remodel", :from => :hand, :required => true
      if card
        max_cost = card.cost + 2
        new_card = choose_card "Choose a card from the supply costing up to #{max_cost}", :from => :supply, :max_cost => max_cost
        trash card
        gain new_card
      end
    end
  end
  
  class Smithy < Card
    set :base
    type :action
    cost 4
    cards 3
  end

  class Spy < Card
    set :base
    type :action, :attack
    cost 4
    cards 1
    actions 1

    def on_play
      ([current_player] + attacked_players).each do |player|
        card = player.draw_from_deck
        player.reveal card
        choice = choose_one ["Discard", "Put it back"], [:discard, :deck]
        if choice == :discard
          player.discard card
        elsif choice == :deck
          player.put_on_deck card
        end
      end
    end
  end  

  class Thief < Card
    set :base
    type :action, :attack
    cost 4

    def on_play
      attacked_players.each do |player|
        cards = player.reveal_cards_from_deck(2)
        treasure = pick_a_treasure(cards)
        if treasure
          player.trash treasure
          if ask "Gain a #{treasure}?"
            gain treasure.class
          end
        end
        remaining = cards.reject {|c| c == treasure}
        player.discard remaining
      end
    end

    def pick_a_treasure(cards)
      treasures = cards.select(&:treasure?)
      return nil unless treasures.any?

      treasures_by_class = treasures.reduce({}) { |h,t| h[t.class] = t; h }
      treasure_classes = treasures_by_class.keys
      treasure_class = choose_one treasure_classes, treasure_classes
      treasures_by_class[treasure_class]
    end
  end
  
  class ThroneRoom < Card
    set :base
    type :action
    cost 4
    multiplier 2

    def on_play
      card = choose_card "Choose a card to play twice", :from => :hand, :required => true
      if card
        2.times do
          play card, :played_by_card => self
        end
      end
    end
  end
  
  class CouncilRoom < Card
    set :base
    type :action
    cost 5
    cards 4
    buys 1
    
    def on_play
      other_players.each do |player|
        player.draw
      end
    end
  end
  
  class Festival < Card
    set :base
    type :action
    cost 5
    actions 2
    coins 2
    buys 1
  end
  
  class Laboratory < Card
    set :base
    type :action
    cost 5
    cards 2
    actions 1
  end
  
  class Library < Card
    set :base
    type :action
    cost 5

    def on_play
      set_aside = []
      while hand.size < 7
        card = draw_from_deck
        break if !card
        if card.action? && ask("Set aside #{card}?")
          set_aside << card
        else
          put_in_hand card
        end
      end
      discard set_aside
    end
  end
  
  class Market < Card
    set :base
    type :action
    cost 5
    cards 1
    actions 1
    coins 1
    buys 1
  end

  class Mine < Card
    set :base
    type :action
    cost 5

    def on_play
      if hand.select(&:treasure?).any?
        card = choose_card "Choose a treasure to trash", :from => :hand, :card_type => :treasure
        if card
          max_cost = card.cost + 3
          new_card = choose_card "Choose a treasure from the supply costing up to #{max_cost}", :from => :supply, :card_type => :treasure, :max_cost => max_cost
          trash card
          gain new_card, :to => :hand
        end
      end
    end
  end
  
  class Witch < Card
    set :base
    type :action, :attack
    cost 5
    cards 2
    
    def on_play
      attacked_players.each do |player|
        player.gain Curse
      end
    end
  end
  
  class Adventurer < Card
    set :base
    type :action
    cost 6

    def on_play
      treasures = []
      set_aside = []
      while treasures.count < 2
        card = draw_from_deck
        break unless card
        if card.treasure?
          treasures << card
        else
          set_aside << card
        end
      end
      put_in_hand treasures
      discard set_aside
    end
  end
  

  #
  # Intrigue
  #
  
  class Courtyard < Card
    set :intrigue
    type :action
    cost 2
    cards 2

    def on_play
      card = choose_card "Choose a card to put back on the deck", :from => :hand, :required => true
      put_on_deck card
    end
  end
  
  class Pawn < Card
    set :intrigue
    type :action
    cost 2

    def on_play
      choices = choose_two ["+1 card", "+1 action", "+$1", "+1 buy"], [:card, :action, :coin, :buy]
      if choices.include?(:card)
        draw 1
      end
      if choices.include?(:action)
        add_actions 1
      end
      if choices.include?(:coin)
        add_coins 1
      end
      if choices.include?(:buy)
        add_buys 1
      end
    end
  end
  
  class SecretChamber < Card
    set :intrigue
#    type :action, :reaction
  end
  
  class GreatHall < Card
    set :intrigue
    type :action, :victory
    cost 3
    cards 1
    actions 1
    vp 1
  end
  
  class Masquerade < Card
    set :intrigue
    type :action
    cost 3
    cards 2

    def on_play
      # choose cards
      cards = players.map do |player|
        card = player.choose_card "Choose a card to pass to #{player_to_left_of(player)}", :from => :hand, :required => :true
        player.hand.delete card
      end

      # pass to next player
      players.rotate.zip(cards) do |player, card|
        player.put_in_hand card
      end

      # optionally trash a card
      card = choose_card "Choose a card to trash", :from => :hand
      trash card if card
    end
  end
  
  class ShantyTown < Card
    set :intrigue
    type :action
    cost 3
    actions 2

    def on_play
      reveal hand
      draw 2 if hand.none? &:action?
    end
  end

  class Steward < Card
    set :intrigue
    type :action
    cost 3

    def on_play
      choice = choose_one ["+2 cards", "+$2", "Trash 2 cards"], [:cards, :coins, :trash]
      if choice == :cards
        draw 2
      elsif choice == :coins
        add_coins 2
      elsif choice == :trash
        cards = choose_cards "Choose 2 cards to trash", :from => :hand, :count => 2, :required => true
        trash cards
      end
    end
  end
  
  class Swindler < Card
    set :intrigue
  end
  
  class WishingWell < Card
    set :intrigue
    type :action
    cost 3
    cards 1
    actions 1

    def on_play
      choice = choose_card "Wish for a card", :from => :supply, :required => true
      card = draw_from_deck
      if card
        reveal card
        if card.is_a?(choice.card_class)
          put_in_hand card
        else
          put_on_deck card
        end
      end
    end
  end
  
  class Baron < Card
    set :intrigue
    type :action
    cost 4
    buys 1

    def on_play
      estate = reveal_from_hand Estate
      if estate
        discard estate
        add_coins 4
      else
        gain Estate
      end
    end
  end
  
  class Bridge < Card
    set :intrigue
  end
  
  class Conspirator < Card
    set :intrigue
    type :action
    cost 4
    coins 2

    def on_play
      if actions_played >= 3
        draw 1
        add_actions 1
      end
    end
  end
  
  class Coppersmith < Card
    set :intrigue
  end
  
  class Ironworks < Card
    set :intrigue
    type :action
    cost 4

    def on_play
      card = choose_card "Choose a card to gain", :from => :supply, :max_cost => 4, :required => true
      if card
        add_actions 1 if card.action?
        add_coins 1 if card.treasure?
        draw 1 if card.victory?
      end
    end
  end
  
  class MiningVillage < Card
    set :intrigue
    type :action
    cost 4
    cards 1
    actions 2

    def on_play
      if ask "Trash this for $2?"
        add_coins 2
        trash self
      end
    end
  end
  
  class Scout < Card
    set :intrigue
  end
  
  class Duke < Card
    set :intrigue
    type :victory
    cost 5

    def vp
      all_cards.count {|c| c.is_a?(Duchy)}
    end
  end
  
  class Minion < Card
    set :intrigue
    type :action, :attack
    cost 5

    def on_play
      choice = choose_one ["+2", "Discard hand and draw 4"], [:coins, :discard]
      if choice == :coins
        add_coins 2
      elsif choice == :discard
        discard_hand
        draw 4

        attacked_players.each do |player|
          if player.hand.size > 4
            player.discard_hand
            player.draw 4
          end
        end
      end
    end
  end
  
  class Saboteur < Card
    set :intrigue
  end
  
  class Torturer < Card
    set :intrigue
    type :action, :attack
    cost 5
    cards 3

    def on_play
      attacked_players.each do |player|
        choice = player.choose_one ["Gain a curse in hand", "Discard 2 cards"], [:curse, :discard]
        if choice == :curse
          player.gain Curse, :to => :hand
        elsif choice == :discard
          cards = player.choose_cards "Discard 2 cards", :from => :hand, :count => 2
          player.discard cards
        end
      end
    end
  end
  
  class TradingPost < Card
    set :intrigue
    type :action
    cost 5

    def on_play
      cards = choose_cards "Choose two cards to trash", :from => :hand, :count => 2, :required => true
      trash cards
      if cards.count == 2
        gain Silver, :to => :hand
      end
    end
  end
  
  class Tribute < Card
    set :intrigue
    type :action
    cost 5

    def on_play
      cards = player_to_left.reveal_cards_from_deck(2)
      unique_cards = cards.map(&:card_class).uniq
      unique_cards.each do |card|
        add_actions 2 if card.action?
        add_coins 2 if card.treasure?
        draw 2 if card.victory?
      end
      player_to_left.discard cards
    end
  end
  
  class Upgrade < Card
    set :intrigue
    type :action
    cost 5
    cards 1
    actions 1

    def on_play
      card = choose_card "Choose a card to upgrade", :from => :hand, :required => true
      if card
        max_cost = card.cost + 1
        new_card = choose_card "Choose a card from the supply costing up to #{max_cost}", :from => :supply, :max_cost => max_cost
        trash card
        gain new_card
      end
    end
  end
  
  class Harem < Card
    set :intrigue
    type :treasure, :victory
    cost 6
    coins 2
    vp 2
  end
  
  class Nobles < Card
    set :intrigue
    type :action, :victory
    cost 6
    vp 2

    def on_play
      choice = choose_one ["+2 actions", "+3 cards"], [:actions, :cards]
      if choice == :actions
        add_actions 2
      elsif choice == :cards
        draw 3
      end
    end
  end
  
  
  #
  # Seaside
  #
  
  class Embargo < Card
    set :seaside
  end
  
  class Haven < Card
    set :seaside
    type :action, :duration
    cost 2
    actions 1
    cards 1

    def on_play
      @set_aside_card = choose_card "Choose a card to set aside for next turn", :from => :hand, :required => true
      hand.delete @set_aside_card
    end

    def on_setup_after_duration
      hand << @set_aside_card
      @set_aside_card = nil
    end
  end
  
  class Lighthouse < Card
    set :seaside
    type :action, :duration
    cost 2
    actions 1
    coins 1

    def on_setup_after_duration
      add_coins 1
    end

    def on_attack
      if in_play?
        player.attack_prevented = true
      end
    end
  end
  
  class NativeVillage < Card
    set :seaside
  end
  
  class PearlDiver < Card
    set :seaside
  end
  
  class Ambassador < Card
    set :seaside
  end
  
  class FishingVillage < Card
    set :seaside
    type :action, :duration
    cost 3
    actions 2
    coins 1

    def on_setup_after_duration
      add_actions 1
      add_coins 1
    end
  end
  
  class Lookout < Card
    set :seaside
  end
  
  class Smugglers < Card
    set :seaside
  end
  
  class Warehouse < Card
    set :seaside
  end
  
  class Caravan < Card
    set :seaside
    type :action, :duration
    cost 4
    actions 1
    coins 1

    def on_setup_after_duration
      draw
    end
  end
  
  class Cutpurse < Card
    set :seaside
  end
  
  class Island < Card
    set :seaside
  end
  
  class Navigator < Card
    set :seaside
  end
  
  class PirateShip < Card
    set :seaside
  end
  
  class Salvager < Card
    set :seaside
    type :action
    cost 4
    
    def on_play
      card = choose_card "Choose a card to trash", :from => :hand
      if card
        add_coins card.cost
        trash card
      end
    end
  end
  
  class SeaHag < Card
    set :seaside
  end
  
  class TreasureMap < Card
    set :seaside
  end
  
  class Bazaar < Card
    set :seaside
    type :action
    cost 5
    cards 1
    actions 2
    coins 1
  end
  
  class Explorer < Card
    set :seaside
  end
  
  class GhostShip < Card
    set :seaside
  end
  
  class MerchantShip < Card
    set :seaside
    type :action, :duration
    cost 5
    coins 2

    def on_setup_after_duration
      add_coins 2
    end
  end
  
  class Outpost < Card
    set :seaside
  end
  
  class Tactician < Card
    set :seaside
  end
  
  class Treasury < Card
    set :seaside
  end
  
  class Wharf < Card
    set :seaside
    type :action, :duration
    cost 5
    cards 2
    buys 1

    def on_setup_after_duration
      draw 2
      add_buys 1
    end
  end
  
  
  #
  # Alchemy
  #

  class Herbalist < Card
    set :alchemy
  end
  
  class Apprentice < Card
    set :alchemy
  end
  
  class Transmute < Card
    set :alchemy
  end
  
  class Vineyard < Card
    set :alchemy
  end
  
  class Apothecary < Card
    set :alchemy
  end
  
  class ScryingPool < Card
    set :alchemy
  end
  
  class University < Card
    set :alchemy
  end
  
  class Alchemist < Card
    set :alchemy
  end
  
  class Familiar < Card
    set :alchemy
    type :action, :attack
    cost 3
    potion true
    cards 1
    actions 1
    
    def on_play
      attacked_players.each do |player|
        player.gain Curse
      end
    end
  end

  class PhilosophersStone < Card
    set :alchemy
  end
  
  class Golem < Card
    set :alchemy
    multiplier 1
  end
  
  class Possession < Card
    set :alchemy
  end
  
  
  #
  # Prosperity
  #

  class Loan < Card
    set :prosperity
  end
  
  class TradeRoute < Card
    set :prosperity
  end
  
  class Watchtower < Card
    set :prosperity
#    type :action, :reaction
    cost 3
  end
  
  class Bishop < Card
    set :prosperity
    type :action
    cost 4
    coins 1

    def on_play
      add_vp_tokens 1
      card = choose_card "Choose a card to trash", :from => :hand
      if card
        add_vp_tokens (card.cost / 2).floor
        trash card
      end
    end
  end

  class Monument < Card
    set :prosperity
    type :action
    cost 4
    coins 2
    
    def on_play
      add_vp_tokens 1
    end
  end
  
  class Quarry < Card
    set :prosperity
  end
  
  class Talisman < Card
    set :prosperity
  end
  
  class WorkersVillage < Card
    set :prosperity
    type :action
    cost 4
    cards 1
    actions 2
    buys 1
  end
  
  class City < Card
    set :prosperity
  end
  
  class Contraband < Card
    set :prosperity
  end
  
  class CountingHouse < Card
    set :prosperity
  end
  
  class Mint < Card
    set :prosperity
    type :action
    cost 5

    def on_play
      card = choose_card "Choose a treasure to gain a copy of", :from => :hand, :card_type => :treasure
      if card
        reveal card
        gain card.class
      end
    end

    def on_buy
      trash treasures_in_play
    end
  end
  
  class Mountebank < Card
    set :prosperity
    type :action, :attack
    cost 5
    coins 2
    
    def on_play
      attacked_players.each do |player|
        curse = player.reveal_from_hand Curse
        if curse
          player.discard curse
        else
          player.gain Curse
          player.gain Copper
        end
      end
    end
  end
  
  class Rabble < Card
    set :prosperity
  end
  
  class RoyalSeal < Card
    set :prosperity
  end
  
  class Vault < Card
    set :prosperity
  end
  
  class Venture < Card
    set :prosperity
  end
  
  class Goons < Card
    set :prosperity
  end
  
  class GrandMarket < Card
    set :prosperity
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
    set :prosperity
    type :treasure
    cost 6
    coins 2

    def on_any_card_bought(card, player)
      if in_play? && card.victory?
        gain Gold
      end
    end
  end
  
  class Bank < Card
    set :prosperity
    type :treasure
    cost 7

    def coins
      treasures_in_play.count
    end
  end
  
  class Expand < Card
    set :prosperity
    type :action
    cost 7

    def on_play
      card = choose_card "Choose a card to expand", :from => :hand, :required => true
      if card
        max_cost = card.cost + 3
        new_card = choose_card "Choose a card from the supply costing up to #{max_cost}", :from => :supply, :max_cost => max_cost
        trash card
        gain new_card
      end
    end
  end
  
  class Forge < Card
    set :prosperity
  end
  
  class KingsCourt < Card
    set :prosperity
    type :action
    cost 7
    multiplier 3

    def on_play
      card = choose_card "Choose a card to play thrice", :from => :hand, :required => false
      if card
        3.times do
          play card, :played_by_card => self
        end
      end
    end
  end
  
  class Peddler < Card
    set :prosperity
    type :action
    cost 8    # 8* (see below)
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
    set :cornucopia
  end
  
  class FarmingVillage < Card
    set :cornucopia
  end
  
  class FortuneTeller < Card
    set :cornucopia
  end
  
  class Menagerie < Card
    set :cornucopia
  end
  
  class HorseTraders < Card
    set :cornucopia
#    type :action, :reaction
    cost 4
  end
  
  class Remake < Card
    set :cornucopia
    type :action
    cost 4

    def on_play
      2.times do
        card = choose_card "Choose a card to remake", :from => :hand, :required => true
        if card
          max_cost = card.cost + 1
          new_card = choose_card "Choose a card from the supply costing up to #{max_cost}", :from => :supply, :max_cost => max_cost
          trash card
          gain new_card
        end
      end
    end
  end
  
  class Tournament < Card
    set :cornucopia
  end
  
  class YoungWitch < Card
    # see preparation.rb for extra rules about bane card
    set :cornucopia
    type :action, :attack
    cost 4
    cards 2

    def on_play
      cards = choose_cards "Choose two cards to discard", :from => :hand, :required => true
      discard cards

      attacked_players.each do |player|
        bane = player.reveal_from_hand bane_card
        unless bane
          player.gain Curse
        end
      end
    end
  end
  
  class Harvest < Card
    set :cornucopia
  end
  
  class HornOfPlenty < Card
    set :cornucopia
  end
  
  class HuntingParty < Card
    set :cornucopia
  end
  
  class Jester < Card
    set :cornucopia
  end
  
  class Fairgrounds < Card
    set :cornucopia
    type :victory
    cost 6
    
    def vp
      num_unique_cards = all_cards.map {|c| c.class }.uniq.size
      num_unique_cards * 2
    end
  end

  
  #
  # Promo
  #

  class BlackMarket < Card
    set :promo
    # Good luck...
  end
  
  class Envoy < Card
    set :promo
  end
  
  class Stash < Card
    set :promo
  end
  
  class WalledVillage < Card
    set :promo
  end

  class Governor < Card
    set :promo
  end

end
