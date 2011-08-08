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
  
  def test_basic_response
    game = Game.new :num_players => 1, :kingdom_cards => [Chancellor]
    player = game.current_player
    
    assert_equal 5, player.deck.size
    
    player.gain Chancellor, :to => :hand
    player.play Chancellor
    assert_equal :waiting_for_choice, player.state
    
    player.respond true

    assert_equal :playing, player.state
    assert_equal 0, player.deck.size
    
    player.end_turn
    
    player.gain Chancellor, :to => :hand
    player.play(Chancellor) { false }
    
    assert_equal :playing, player.state
    assert_not_equal 0, player.deck.size
  end
  
  def test_choose_card
    game = Game.new :num_players => 1, :kingdom_cards => [Salvager]
    player = game.current_player
    
    coins = player.coins_available
    player.gain Salvager, :to => :hand
    player.gain Estate, :to => :hand
    player.play Salvager, :choice => Estate
    
    assert_equal coins + 2, player.coins_available
  end

end
