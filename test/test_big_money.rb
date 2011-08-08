require File.dirname(__FILE__) + '/common'

class TestBigMoney < Test::Unit::TestCase
  
  def print_results?
    ENV['PRINT_RESULTS'] == '1'
  end
  
  def test_big_money_game
    n = 10
    turns = 0
    vp = 0
    spread = 0
    first_player = 0
    
    n.times do
      game = Game.new
    
      until game.game_over? do
        player = game.current_player
        player.play_all_treasures
      
        if player.can_buy(Province)
          player.buy Province
        elsif player.can_buy(Duchy) && game.supply[Province].size < 4
          player.buy Duchy
        elsif player.can_buy(Estate) && game.supply[Province].size < 3
          player.buy Estate
        elsif player.can_buy(Gold)
          player.buy Gold
        elsif player.can_buy(Silver)
          player.buy Silver
        end
      
        player.end_turn
      end
    
      assert game.supply[Province].empty?
      
      winner = game.winner
      loser = game.player_to_left_of winner
      
      winner_vp = winner.total_victory_points
      loser_vp = loser.total_victory_points
      
      turns += winner.turn
      vp += winner_vp
      spread += winner_vp - loser_vp
      first_player += 1 if winner == game.players[0]
    end
    
    avg_turns = turns.to_f / n
    avg_vp = vp.to_f / n
    avg_spread = spread.to_f / n
    avg_first_player = first_player.to_f / n

    if print_results?
      puts "Average turns: #{avg_turns},  Average VP: #{avg_vp},  Average Spread: #{avg_spread},  First Player: #{avg_first_player}"
    end
  end
  
end
