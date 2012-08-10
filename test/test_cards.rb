require File.dirname(__FILE__) + '/common'

class TestCards < Test::Unit::TestCase

  def test_simple_card
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
    assert_gained player, Duchy
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

  def test_get_all_cards
    all_cards = Dominion.all_cards
  end

end

