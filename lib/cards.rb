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

    def do_action
      choose :type => :card, :message => "Choose a card to trash" do |card|
        vp_tokens = 1 + (card.cost / 2).floor
        add_vp_tokens vp_tokens
      end
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

    def do_action
      gain Silver, :to => :deck
      other_players.each do |player|
        player.reveal :type => :victory, :attack => true do |card|
          player.put card, :to => :deck if card
        end
      end
    end
  end

  class Chancellor < Card
    type :action
    cost 3
    coins 2
  
    def do_action
      choose :type => :bool, :message => "Immediately put deck into discard pile?" do |reshuffle|
        if reshuffle
          discard_pile += deck
          deck.clear
        end
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
        num_actions = actions_in_play.size + durations_in_play.size
        [8 - 2 * num_actions, 0].max
      else
        8
      end
    end
  end
  
  class Witch < Card
    type :action, :attack
    cost 5
    cards 2
    
    def do_action
      other_players.each do |player|
        player.gain Curse
      end
    end
  end
  
  class Mountebank < Card
    type :action, :attack
    cost 5
    coins 2
    
    def do_action
      other_players.each do |player|
        player.reveal :type => Curse, :attack => true do |card|
          unless card
            player.gain Copper
            player.gain Curse
          end
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
    
    def do_action
      other_players.each do |player|
        player.gain Curse
      end
    end
  end

end
