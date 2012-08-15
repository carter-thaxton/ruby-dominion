require File.dirname(__FILE__) + '/common'

class TestCards < Test::Unit::TestCase

  def test_village
    assert Village.action?
    assert Village.kingdom?
    assert !Village.victory?
    
    v = Village.new

    assert_equal 2, v.actions
    assert_equal 1, v.cards
    assert_equal 0, v.buys
    
    assert v.action?
    assert v.kingdom?
    assert !v.victory?
    assert !v.base?
  end

  def test_peddler
    # out of context
    p = Peddler.new
    assert_equal 8, p.cost

    # in game context
    game = MockGame.new
    p = Peddler.new game

    game.buy_phase = true
    game.actions_in_play = Array.new 5
    assert_equal 0, p.cost
    
    game.buy_phase = false
    assert_equal 8, p.cost
    
    game.buy_phase = true
    game.actions_in_play = []
    assert_equal 8, p.cost
    
    game.actions_in_play = Array.new 2
    assert_equal 4, p.cost
  end

  def test_feast
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Feast]
    player = game.current_player
    
    player.gain Feast, :to => :hand
    player.play Feast, :choice => Duchy
    assert_has_a Duchy, player.discard_pile
  end

  def test_throne_room_feast
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Feast, ThroneRoom]
    player = game.current_player
    
    player.gain [ThroneRoom, Feast], :to => :hand
    player.strategy = respond_with Feast, Duchy, Duchy
    player.play ThroneRoom
    assert_has_count Duchy, player.discard_pile, 2
    assert_has_count Feast, game.trash_pile, 1
  end

  def test_gardens
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Gardens]
    player = game.current_player
    
    7.times do
      player.gain Gardens
    end

    31.times do
      player.gain Copper
    end

    # 38 cards -> 3 pts per Gardens * 7 Gardens = 21 VP
    assert_equal 21, player.total_victory_points
  end

  def test_militia
    game = Game.new :num_players => 3, :no_cards => true, :kingdom_cards => [Militia]
    p1 = game.players[0]
    p2 = game.players[1]
    p3 = game.players[2]

    p1.gain Militia, :to => :hand
    5.times do
      p2.gain Copper, :to => :hand
    end
    3.times do
      p3.gain Copper, :to => :hand
    end

    p2.strategy = respond_with [Copper, Copper]

    p1.play Militia

    assert_equal 3, p2.hand.size
    assert_equal 3, p3.hand.size
  end

  def test_remodel
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Remodel]
    player = game.current_player

    player.gain [Remodel, Estate], :to => :hand

    player.strategy = respond_with Estate, Silver  # trash Estate, gain a Silver
    player.play Remodel

    assert_has_a Silver, player.discard_pile
    assert_equal 0, player.hand.size
  end

  def test_remake
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Remake]
    player = game.current_player

    player.gain [Remake, Estate, Copper], :to => :hand

    player.strategy = respond_with Estate, Silver, Copper  # trash Estate, gain a Silver, trash Copper (no replacement)
    player.play Remake

    assert_has_a Silver, player.discard_pile
    assert_equal 0, player.hand.size
  end

  def test_upgrade
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Upgrade]
    player = game.current_player

    player.gain [Upgrade, Upgrade], :to => :hand
    player.gain [Estate, Copper], :to => :deck

    player.strategy = respond_with Estate, Silver, Copper  # trash Estate, gain a Silver, trash Copper (no replacement)
    player.play Upgrade
    player.play Upgrade

    assert_has_a Silver, player.discard_pile
    assert_equal 0, player.hand.size
    assert_equal 1, player.actions_available
  end

  def test_spy
    game = Game.new :num_players => 2, :no_cards => true, :kingdom_cards => [Spy]
    p1 = game.players[0]
    p2 = game.players[1]

    p1.gain Spy, :to => :hand
    p1.gain [Copper, Silver, Estate], :to => :deck

    p2.gain [Silver, Estate], :to => :deck

    p1.strategy = respond_with :deck, :discard   # deck for self, discard for p2
    p1.play Spy

    assert_has_a Copper, p1.hand
    assert_has_a Silver, p1.deck
    assert_has_a Estate, p1.deck
    assert p1.discard_pile.empty?

    assert_has_a Estate, p2.deck
    assert_has_a Silver, p2.discard_pile
  end

  def test_thief
    game = Game.new :num_players => 3, :no_cards => true, :kingdom_cards => [Thief]
    p1 = game.players[0]
    p2 = game.players[1]
    p3 = game.players[2]

    p1.gain Thief, :to => :hand

    p2.gain [Silver, Copper], :to => :deck
    p3.gain [Copper, Duchy], :to => :deck

    p1.strategy = respond_with Silver, true, false    # choose to gain Silver from p1, don't gain Copper from p2
    p1.play Thief

    assert_has_a Silver, p1.discard_pile
    assert_has_no Copper, p1.discard_pile
    assert_has_no Silver, p2.deck
    assert_has_no Silver, p2.discard_pile
    assert_has_a Copper, p2.discard_pile
    assert_has_no Copper, p3.discard_pile
    assert_has_a Duchy, p3.discard_pile
    assert_has_a Copper, game.trash_pile
  end

  def test_library
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Library, Village]
    player = game.current_player

    player.gain [Library, Estate, Estate, Estate, Estate], :to => :hand
    player.gain [Copper, Village, Copper, Library, Copper, Silver, Silver], :to => :deck

    player.strategy = respond_with true, false    # set aside the Village, but not the second Library
    player.play Library

    assert_equal 7, player.hand.size
    assert_has_a Copper, player.hand
    assert_has_a Library, player.hand
    assert_has_a Village, player.discard_pile
    assert_has_a Silver, player.deck
    assert_has_no Silver, player.hand
  end

  def test_library_with_small_deck
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Library, Village]
    player = game.current_player

    player.gain [Library, Estate, Estate, Estate, Estate], :to => :hand
    player.gain [Copper], :to => :deck

    player.play Library

    assert_equal 5, player.hand.size
  end

  def test_mine
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Mine]
    player = game.current_player

    player.gain [Mine, Silver], :to => :hand

    player.strategy = respond_with Silver, Gold
    player.play Mine

    assert_has_a Silver, game.trash_pile
    assert_has_a Gold, player.hand
  end

  def test_adventurer
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Adventurer]
    player = game.current_player

    player.gain Adventurer, :to => :hand
    player.gain [Silver, Estate, Estate, Estate, Copper, Gold, Duchy], :to => :deck

    player.play Adventurer

    assert_has_a Silver, player.hand
    assert_has_a Copper, player.hand
    assert_has_no Gold, player.hand
    assert_has_no Estate, player.hand
    assert_has_a Gold, player.deck
    assert_has_a Duchy, player.deck
    assert_has_a Estate, player.discard_pile
  end

  def test_mint
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Mint]
    player = game.current_player

    player.gain [Copper, Copper, Copper, Copper, Copper], :to => :hand
    player.gain [Gold], :to => :deck

    player.play_all_treasures
    player.buy Mint
    player.end_turn
    assert_has_a Copper, game.trash_pile
    assert_equal 5, game.trash_pile.size

    assert_has_no Copper, player.hand
    assert_has_a Mint, player.hand
    assert_has_a Gold, player.hand

    player.strategy = respond_with Gold
    player.play Mint

    assert_has_a Gold, player.hand
    assert_has_a Gold, player.discard_pile
  end

  def test_courtyard
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Courtyard]
    player = game.current_player

    player.gain [Courtyard, Estate, Estate], :to => :hand
    player.gain [Gold, Silver], :to => :deck

    player.strategy = respond_with Gold
    player.play Courtyard

    assert_has_a Gold, player.deck
    assert_has_a Silver, player.hand
    assert_has_a Estate, player.hand
  end

  def test_pawn
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Pawn]
    player = game.current_player

    player.gain Pawn, :to => :hand
    player.gain [Estate, Copper], :to => :deck

    player.strategy = respond_with [:card, :action]
    player.play Pawn

    assert_has_a Estate, player.hand
    assert_has_a Copper, player.deck
    assert_equal 1, player.actions_available
    assert_equal 1, player.buys_available
    assert_equal 0, player.coins_available
    player.end_turn

    player.gain Pawn, :to => :hand
    player.strategy = respond_with [:buy, :coin]
    player.play Pawn

    assert_equal 0, player.actions_available
    assert_equal 2, player.buys_available
    assert_equal 1, player.coins_available
  end

  def test_steward
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Steward]
    player = game.current_player

    player.gain [Steward, Silver, Estate, Copper], :to => :hand

    player.strategy = respond_with :trash, [Estate, Copper]
    player.play Steward

    assert_has_a Silver, player.hand
    assert_has_no Estate, player.hand
    assert_has_no Copper, player.hand
    assert_has_a Estate, game.trash_pile
    assert_has_a Copper, game.trash_pile
    assert_equal 0, player.actions_available
    assert_equal 0, player.coins_available
    player.end_turn

    player.gain Steward, :to => :hand
    player.strategy = respond_with :coins
    player.play Steward

    assert_equal 0, player.actions_available
    assert_equal 2, player.coins_available
  end

  def test_shanty_town
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [ShantyTown]
    player = game.current_player

    player.gain [ShantyTown, ShantyTown, Estate, Copper], :to => :hand
    player.gain [Silver, Silver, Duchy], :to => :deck

    assert_equal 1, player.actions_available
    assert_equal 4, player.hand.size

    player.play ShantyTown
    assert_equal 2, player.actions_available
    assert_equal 3, player.hand.size
    assert_has_no Silver, player.hand

    player.play ShantyTown
    assert_equal 3, player.actions_available
    assert_equal 4, player.hand.size
    assert_has_a Silver, player.hand
  end

  def test_duke
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Duke]
    player = game.current_player
    
    4.times do
      player.gain Duchy
    end

    2.times do
      player.gain Duke
    end

    # 4 * 3 VP per Duchy + 2 * 4 VP per Duke = 20 VP
    assert_equal 20, player.total_victory_points
  end

  def test_wishing_well
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [WishingWell]
    player = game.current_player

    player.gain [WishingWell, WishingWell], :to => :hand
    player.gain [Copper, Estate, Silver, Duchy], :to => :deck

    player.play WishingWell, :choice => Gold
    assert_equal 2, player.hand.size
    assert_has_a Copper, player.hand
    assert_has_no Gold, player.hand
    assert_has_no Estate, player.hand

    player.play WishingWell, :choice => Silver
    assert_equal 3, player.hand.size
    assert_has_a Estate, player.hand
    assert_has_a Silver, player.hand
    assert_has_no Duchy, player.hand
  end

  def test_hoard
    game = Game.new :num_players => 2, :no_cards => true, :kingdom_cards => [Hoard]
    p1 = game.current_player
    p2 = game.players[1]

    p1.gain [Hoard, Silver, Copper], :to => :hand
    p2.gain [Hoard, Silver, Copper], :to => :hand

    p1.play_all_treasures
    p1.buy Duchy
    assert_has_a Gold, p1.discard_pile
    assert_has_no Gold, p2.discard_pile
  end

  def test_bank
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Bank]
    player = game.current_player

    player.gain [Bank, Bank, Copper, Copper], :to => :hand

    player.play Copper
    player.play Copper
    player.play Bank
    player.play Bank
    assert_equal 9, player.coins_available
  end

  def test_throne_room_kings_court
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [ThroneRoom, KingsCourt, Monument]
    player = game.current_player
    
    player.gain [ThroneRoom, KingsCourt, Monument, Monument], :to => :hand

    player.strategy = respond_with KingsCourt, Monument, Monument

    player.play ThroneRoom

    assert_equal 12, player.coins_available
    assert_equal 6, player.vp_tokens
    assert_equal 0, player.actions_available
  end

  def test_fishing_village
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [FishingVillage]
    player = game.current_player
    
    player.gain FishingVillage, :to => :hand
    player.play FishingVillage

    assert_equal 2, player.actions_available
    assert_equal 1, player.coins_available

    player.end_turn

    assert_has_a FishingVillage, player.actions_in_play_from_previous_turn
    assert_equal 0, player.hand.size
    assert_equal 2, player.actions_available
    assert_equal 1, player.coins_available
  end

  def test_haven
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Haven]
    player = game.current_player
    
    player.gain [Haven, Copper], :to => :hand
    player.gain [Silver, Estate, Estate, Estate, Estate, Estate, Estate], :to => :deck
    player.play Haven, :choice => Silver
    assert_equal 1, player.actions_available
    assert_has_no Silver, player.hand
    assert_has_no Silver, player.deck
    assert_has_no Silver, player.discard_pile
    player.play_all_treasures
    assert_equal 1, player.coins_available
    player.end_turn

    assert_has_a Haven, player.actions_in_play_from_previous_turn
    assert_has_no Haven, player.hand
    assert_has_a Silver, player.hand
    assert_equal 6, player.hand.size
  end

  def test_young_witch
    game = Game.new :num_players => 4, :no_cards => true, :kingdom_cards => [YoungWitch, Moat]
    p1 = game.players[0]
    p2 = game.players[1]
    p3 = game.players[2]
    p4 = game.players[3]

    assert game.bane_card, "Game should have a bane card when playing with Young Witch"

    p1.gain [YoungWitch, Copper, Copper], :to => :hand
    p1.gain [Estate, Estate, Silver], :to => :deck

    p2.gain game.bane_card, :to => :hand
    p4.gain Moat, :to => :hand

    p1.strategy = respond_with Estate, Estate
    p2.strategy = respond_with true
    p4.strategy = respond_with true
    p1.play YoungWitch

    assert_has_a Copper, p1.hand
    assert_has_a Estate, p1.discard_pile
    assert_has_a Silver, p1.deck
    assert_has_no Silver, p1.hand

    assert_has_no Curse, p2.discard_pile
    assert_has_a Curse, p3.discard_pile
    assert_has_no Curse, p4.discard_pile
  end

  def test_baron
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Baron]
    player = game.current_player
    
    player.gain [Baron, Estate], :to => :hand
    player.play Baron, :choice => true
    assert_equal 4, player.coins_available
    player.end_turn
    assert_has_count Estate, player.all_cards, 1

    player.play Baron, :choice => false
    assert_equal 0, player.coins_available
    player.end_turn
    assert_has_count Estate, player.all_cards, 2
  end

  def test_torturer
    game = Game.new :num_players => 2, :no_cards => true, :kingdom_cards => [Torturer, KingsCourt]
    p1 = game.players[0]
    p2 = game.players[1]

    p1.gain [KingsCourt, Torturer], :to => :hand
    p1.gain [Copper] * 9, :to => :deck

    p2.gain [Estate] * 5, :to => :hand
    p2.strategy = respond_with :curse, :discard, [Estate, Estate], :discard, [Estate, Estate]

    p1.play KingsCourt, :choice => Torturer

    assert_has_count Copper, p1.hand, 9
    assert_equal 2, p2.hand.size
    assert_has_a Curse, p2.hand
  end
end

