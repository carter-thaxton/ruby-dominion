require File.dirname(__FILE__) + '/common'

class TestSetup < Test::Unit::TestCase

  def test_basic_play
    game = Game.new :num_players => 1
    player = game.current_player
    
    assert game.action_phase?
    assert_equal 1, player.actions_available
    assert_equal 1, player.buys_available
    assert_equal 0, player.coins_available
    
    player.play_all_treasures
    assert game.treasure_phase?
    assert player.coins_available >= 2    # even with random deck, at least a 5/2 opening
    coppers = player.coins_available
    assert_equal 5 - coppers, player.hand.size
    assert_equal coppers, player.treasures_in_play.size
    
    player.buy Estate
    assert game.buy_phase?
    assert_equal coppers - 2, player.coins_available    # Estate costs 2
    assert_equal 0, player.buys_available
    
    player.end_turn
    assert game.action_phase?
  end
  
  def test_winner
    game = Game.new :no_cards => true

    game.players[0].gain Estate
    assert_equal game.players[0], game.winner
    game.players[1].gain Duchy
    assert_equal game.players[1], game.winner
    game.players[0].gain Duchy
    assert_equal game.players[0], game.winner
    game.players[1].gain Province
    assert_equal game.players[1], game.winner
  end

end
