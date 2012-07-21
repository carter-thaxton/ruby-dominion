
module Dominion

  class ConsoleStrategy
    def choose(player, card, options)
      puts "#{player}: #{card} - #{options[:message]}"
    end
  end

end
