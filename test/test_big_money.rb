require File.dirname(__FILE__) + '/common'

class TestBigMoney < Test::Unit::TestCase
  
  def print_results?
    ENV['PRINT_RESULTS'] == '1'
  end
  
  def test_big_money_game
    game = Game.new
    
    until game.game_over? do
      player = game.current_player
      player.play_all_treasures
      
      if player.coins_available >= 8
        player.buy Province
      elsif player.coins_available >= 5 && game.supply[Province].size < 4 && !game.supply[Duchy].empty?
        player.buy Duchy
      elsif player.coins_available >= 2 && game.supply[Province].size < 3 && !game.supply[Estate].empty?
        player.buy Estate
      elsif player.coins_available >= 6 && !game.supply[Gold].empty?
        player.buy Gold
      elsif player.coins_available >= 3 && !game.supply[Silver].empty?
        player.buy Silver
      end
      
      player.end_turn
    end
    
    assert game.supply[Province].empty?
    
    if print_results?
      winner = game.winner
      loser = game.player_to_left_of winner
    
      puts "#{winner} wins after #{winner.turn} turns, with #{winner.total_victory_points} VP, $#{winner.total_treasure}, and #{winner.all_cards.size} cards"
      puts "#{loser} took #{loser.turn} turns, with #{loser.total_victory_points} VP, $#{loser.total_treasure}, and #{loser.all_cards.size} cards"
    end
  end
  
end
