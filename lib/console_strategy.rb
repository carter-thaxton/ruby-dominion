require 'fiber'

module Dominion

	class Console
  	@@fiber = nil
  	@@waiting_for_response = false

	  def self.start_new_game
			g = Game.new :strategy => ConsoleStrategy.new
			p1 = g.players[0]
			p2 = g.players[1]
			f = Fiber.new do
				puts "Welcome to Dominion\n  g - game\n  p1 - player 1\n  p2 - player 2\n"
				Pry.quiet = true
				Pry.prompt = proc { '> ' }
				Pry.start binding
				puts "Bye!"
				exit
			end
			f.resume
		end

	  def self.get_response
      @@waiting_for_response = true
      @@fiber = Fiber.current
      Fiber.yield
	  end

    def self.waiting_for_response?
    	@@waiting_for_response
    end

	  def self.respond(value)
	  	raise "Cannot respond unless waiting for response" unless waiting_for_response?
	  	@@waiting_for_response = false
	  	@@fiber.resume value
	  end
	end

  def waiting_for_response?
  	Console.waiting_for_response?
  end

  def respond(value)
  	Console.respond(value)
  end

  class ConsoleStrategy
    def choose(player, options)
      puts "#{player}: #{player.card_in_play} - #{options[:message]}"
      Console.get_response
    end
  end

end
