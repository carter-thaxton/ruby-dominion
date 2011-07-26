module Dominion
  
  class Copper < Card
    type :base, :treasure
    cost 0
    coins 1
  end

  class Silver < Card
    type :base, :treasure
    cost 3
    coins 2
  end

  class Gold < Card
    type :base, :treasure
    cost 6
    coins 3
  end

  class Platinum < Card
    type :base, :treasure
    cost 9
    coins 5
  end

  class Estate < Card
    type :base, :victory
    cost 2
    vp 1
  end

  class Duchy < Card
    type :base, :victory
    cost 5
    vp 3
  end

  class Province < Card
    type :base, :victory
    cost 8
    vp 6
  end

  class Colony < Card
    type :base, :victory
    cost 11
    vp 10
  end

  class Curse < Card
    type :base, :curse
    cost 0
  end


  class GreatHall < Card
    type :action, :victory
    cost 3
    cards 1
    actions 1
    vp 1
  end

  class Bishop < Card
    type :action
    cost 4
    coins 1
    vp_tokens :dynamic
  
    def play(game)
      @trashed_card = yield :choose_card_to_trash
    end
  
    def vp_tokens(game)
      1 + (@trashed_card.cost(game) / 2).floor
    end
  end

  class Village < Card
    type :action
    cost 3
    cards 1
    actions 2
  end

  class Bureaucrat < Card
    type :action, :attack
    cost 3
    coins 2

    def play(game)
      game.gain Silver, :to => :deck
      game.other_players.each do |player|
        @revealed = player.reveal :from => :hand, :type => :victory?, :attack => true
        player.put @revealed, :to => :deck if @revealed
      end
    end
  end

  class Chancellor < Card
    type :action
    cost 3
    coins 2
  
    def play(game)
      @reshuffle = yield :immediately_put_deck_into_discard_pile?
    end
  
    def cleanup(game)
      super.cleanup(game)
      if @reshuffle
        game.discard += game.deck
        game.deck = []
      end
    end
  end

  class Peddler < Card
    type :action
    cost :dynamic   # 8*
    cards 1
    actions 1
    coins 1
  
    def cost(game)
      if game.buy_phase?
        [8 - 2 * game.actions_played, 0].max
      else
        8
      end
    end
  end

end
