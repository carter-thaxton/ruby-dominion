require File.dirname(__FILE__) + '/common'

class TestCards < Test::Unit::TestCase
  include Dominion

  def test_game_state
    game = Game.new
    assert !game.in_progress?
    
    game.setup
    assert game.in_progress?
    assert_equal 2, game.num_players
  end

end
