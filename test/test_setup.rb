require File.dirname(__FILE__) + '/common'

class TestSetup < Test::Unit::TestCase

  def test_get_all_cards
    all_cards = Dominion.all_cards
  end

  def test_initial_count_in_supply
    assert_equal 10, Preparation.initial_count_in_supply(Village, 2)

    assert_equal 10, Preparation.initial_count_in_supply(Curse, 2)
    assert_equal 20, Preparation.initial_count_in_supply(Curse, 3)
    assert_equal 30, Preparation.initial_count_in_supply(Curse, 4)

    assert_equal  8 + 0*3, Preparation.initial_count_in_supply(Estate, 0)
    assert_equal  8 + 1*3, Preparation.initial_count_in_supply(Estate, 1)
    assert_equal  8 + 2*3, Preparation.initial_count_in_supply(Estate, 2)
    assert_equal 12 + 3*3, Preparation.initial_count_in_supply(Estate, 3)
    assert_equal 12 + 4*3, Preparation.initial_count_in_supply(Estate, 4)

    game = Game.new :num_players => 1
  end

  def test_game_in_progress
    game = Game.new :no_prepare => true
    assert !game.in_progress?
    
    game.prepare
    assert game.in_progress?
    
    game = Game.new
    assert game.in_progress?
    assert_equal 2, game.num_players

    assert !Card::BASE_CONTEXT.in_progress?
  end
  
  def test_player_setup
    game = Game.new :players => [:chloe, :fletcher, :sara]
    
    assert_equal 3, game.num_players

    assert_equal :chloe, game.players[0].identity
    assert_equal 0, game.players[0].position
    
    assert_equal :fletcher, game.players[1].identity
    assert_equal 1, game.players[1].position

    assert_equal :sara, game.players[2].identity
    assert_equal 2, game.players[2].position
    
    game = Game.new :num_players => 4
    assert_equal 4, game.num_players
    game.players.each_with_index do |player, position|
      assert_nil player.identity
      assert_equal position, player.position
    end
  end
  
  def test_player_cards_setup
    game = Game.new
    
    game.players.each do |player|
      assert_equal 5, player.hand.size
      assert_equal 5, player.deck.size
      assert player.discard_pile.empty?
    end
  end
  
  def test_player_no_cards_setup
    game = Game.new :no_cards => true
    
    game.players.each do |player|
      assert player.hand.empty?
      assert player.deck.empty?
      assert player.discard_pile.empty?
    end
  end

  def test_bane_card
    game = Game.new :kingdom_cards => [YoungWitch]
    assert game.bane_card, "Bane card should be present when Young Witch is in kingdom"
    assert game.kingdom_cards.include?(game.bane_card), "Bane should should be part of kingdom cards"
    assert_equal 2, game.kingdom_cards.count, "Bane card should be in addition to other kingdom cards"
    assert game.supply[game.bane_card], "Bane card should be part of supply"
  end
  
end
