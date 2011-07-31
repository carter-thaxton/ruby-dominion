require 'card'

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
  
  class Potion < Card
    type :base, :treasure, :potion
    cost 4
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
  
  class Fairgrounds < Card
    type :victory
    cost 6
    vp :dynamic
    
    def vp
      num_unique_cards = owner.all_cards.map {|c| c.class }.uniq.length
      num_unique_cards * 2
    end
  end

  class Bishop < Card
    type :action
    cost 4
    coins 1
    vp_tokens :dynamic

    def play
      @trashed_card = yield :choose_card_to_trash
    end
  
    def vp_tokens
      1 + (@trashed_card.cost / 2).floor
    end
  end

  class Village < Card
    type :action
    cost 3
    cards 1
    actions 2
  end
  
  class Smithy < Card
    type :action
    cost 4
    cards 3
  end

  class Bureaucrat < Card
    type :action, :attack
    cost 3
    coins 2

    def play
      gain Silver, :to => :deck
      other_players.each do |player|
        revealed = player.reveal :type => :victory, :attack => true
        player.put @revealed, :to => :deck if revealed
      end
    end
  end

  class Chancellor < Card
    type :action
    cost 3
    coins 2
  
    def play
      @reshuffle = yield :immediately_put_deck_into_discard_pile?
    end
  
    def cleanup
      super.cleanup
      if @reshuffle
        discard_pile += deck
        deck.clear
      end
    end
  end

  class Peddler < Card
    type :action
    cost :dynamic   # 8* (see below)
    cards 1
    actions 1
    coins 1
  
    def cost
      if buy_phase?
        [8 - 2 * actions_played, 0].max
      else
        8
      end
    end
  end
  
  class Witch < Card
    type :action, :attack
    cost 5
    cards 2
    
    def play
      other_players.each do |player|
        player.gain Curse
      end
    end
  end
  
  class Mountebank < Card
    type :action, :attack
    cost 5
    coins 2
    
    def play
      other_players.each do |player|
        revealed = player.reveal :type => Curse, :attack => true
        unless revealed
          player.gain Copper
          player.gain Curse
        end
      end
    end
  end
  
  class BlackMarket < Card
    # Good luck...
  end
  
  class Familiar < Card
    type :action, :attack
    cost 3
    potion true
    cards 1
    actions 1
    
    def play
      other_players.each do |player|
        player.gain Curse
      end
    end
  end

end
