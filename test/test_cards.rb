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
    
    # play Feast
    player.gain Feast, :to => :hand
    player.play Feast, :choice => Duchy
    assert_has_a Duchy, player.discard_pile
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

    p2.strategy = MockStrategy.new([[Copper, Copper]])

    p1.play Militia

    assert_equal 3, p2.hand.size
    assert_equal 3, p3.hand.size
  end

  def test_remodel
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Remodel]
    player = game.current_player

    player.gain Remodel, :to => :hand
    player.gain Estate, :to => :hand

    player.strategy = MockStrategy.new([Estate, Silver])  # trash Estate, gain a Silver
    player.play Remodel

    assert_has_a Silver, player.discard_pile
    assert_equal 0, player.hand.size
  end

  def test_spy
    game = Game.new :num_players => 2, :no_cards => true, :kingdom_cards => [Spy]
    p1 = game.players[0]
    p2 = game.players[1]

    p1.gain Spy, :to => :hand
    p1.gain [Copper, Silver, Estate], :to => :deck

    p2.gain [Silver, Estate], :to => :deck

    p1.strategy = MockStrategy.new([:deck, :discard])   # deck for self, discard for p2
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
    p3.gain [Estate, Duchy], :to => :deck

    p1.strategy = MockStrategy.new([Silver, true])    # choose to gain Silver from p1
    p1.play Thief

    assert_has_a Silver, p1.discard_pile
    assert_has_no Silver, p2.deck
    assert_has_no Silver, p2.discard_pile
    assert_has_a Copper, p2.discard_pile
    assert_has_a Estate, p3.discard_pile
    assert_has_a Duchy, p3.discard_pile
  end

  def test_library
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Library, Village]
    player = game.current_player

    player.gain [Library, Estate, Estate, Estate, Estate], :to => :hand
    player.gain [Copper, Village, Copper, Library, Copper, Silver, Silver], :to => :deck

    player.strategy = MockStrategy.new([true, false])    # set aside the Village, but not the second Library
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

  def test_get_all_cards
    all_cards = Dominion.all_cards
  end

end

