
module Dominion

  class DefaultStrategy
    def on_ask(player, card, message, options)
      puts "#{player}: #{card} - #{message}"
    end
    
    def on_choose_card(player, card, message, options)
    end
    
    def on_choose_cards(player, card, message, options)
    end
  end

end

