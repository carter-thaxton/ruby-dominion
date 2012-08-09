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
  
  def test_ask_using_chancellor
    game = Game.new :num_players => 1, :kingdom_cards => [Chancellor]
    player = game.current_player
    
    assert_equal 5, player.deck.size

    # synchronous, using :choice
    player.gain Chancellor, :to => :hand
    player.play Chancellor, :choice => true
    assert !player.choice_in_progress, "should not be waiting for choice"
    assert_equal 0, player.deck.size
    player.end_turn

    # asynchronous, using respond
    player.gain Chancellor, :to => :hand
    player.play Chancellor
    assert player.choice_in_progress, "should be waiting for choice"
    player.respond true
    assert !player.choice_in_progress, "should not be waiting for choice"
    assert_equal 0, player.deck.size
    player.end_turn
  end

  def test_choose_one_using_nobles
    game = Game.new :num_players => 1, :kingdom_cards => [Nobles]
    player = game.current_player

    # choose actions
    player.gain Nobles, :to => :hand
    orig_hand_size = player.hand.size
    player.play Nobles, :choice => :cards
    assert_equal orig_hand_size + 2, player.hand.size
    player.end_turn

    # choose cards
    player.gain Nobles, :to => :hand
    player.play Nobles, :choice => :actions
    assert_equal 2, player.actions_available
    player.end_turn
  end
  
  def test_choose_card_using_salvager
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Salvager]
    player = game.current_player
    
    # synchronous, using Card class
    coins = player.coins_available
    player.gain Salvager, :to => :hand
    player.gain Estate, :to => :hand
    player.play Salvager, :choice => Estate
    assert_equal coins + 2, player.coins_available
    player.end_turn
    
    # synchronous, using card instance
    coins = player.coins_available
    player.gain Salvager, :to => :hand
    estate = player.gain Estate, :to => :hand
    player.play Salvager, :choice => estate
    assert_equal coins + 2, player.coins_available
    player.end_turn
  end
  
  def test_choose_cards_using_chapel
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Chapel]
    player = game.current_player
    
    # synchronous, using :choice => [Card, Card]
    player.gain Chapel, :to => :hand
    player.gain Estate, :to => :hand
    player.gain Estate, :to => :hand
    player.gain Copper, :to => :hand
    player.gain Copper, :to => :hand
    player.play Chapel, :choice => [Estate, Estate, Copper]
    assert_equal 1, player.hand.size
    player.play_all_treasures
    assert_equal 1, player.coins_available
    player.end_turn
    
    # synchronous, using :choice => Card
    player.hand.clear
    player.gain Chapel, :to => :hand
    player.gain Estate, :to => :hand
    player.gain Estate, :to => :hand
    player.gain Copper, :to => :hand
    player.gain Copper, :to => :hand
    player.play Chapel, :choice => Estate
    assert_equal 3, player.hand.size
    player.play_all_treasures
    assert_equal 2, player.coins_available
    player.end_turn
  end
  
  def test_no_choice_using_moneylender
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Moneylender]
    player = game.current_player
    
    # play Moneylender when no Copper in hand
    player.gain Moneylender, :to => :hand
    player.gain Estate, :to => :hand
    player.play Moneylender
    player.play_all_treasures
    assert_equal 0, player.coins_available
    player.end_turn

    # play Moneylender when Copper is in hand
    player.gain Moneylender, :to => :hand
    player.gain Copper, :to => :hand
    player.gain Copper, :to => :hand
    player.play Moneylender
    player.play_all_treasures
    assert_equal 4, player.coins_available
    player.end_turn
  end

  def test_attack_with_reactions_using_minion
    game = Game.new :num_players => 3, :kingdom_cards => [Minion, Moat]
    player = game.current_player
    player2 = game.players[1]
    player3 = game.players[2]

    player.gain Minion, :to => :hand
    player2.gain Moat, :to => :hand

    player.play Minion
    assert game.waiting_for_reactions?
    assert player2.choice_in_progress       # reveal Moat?
    assert !player3.choice_in_progress

    player2.respond true
    assert !game.waiting_for_reactions?

    player.respond :cards
    assert_equal 4, player.hand.size
    assert_equal 5, player2.hand.size       # revealed Moat
    assert_equal 4, player3.hand.size       # no Moat
  end

end
