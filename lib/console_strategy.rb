require 'fiber'

module Dominion

	class Console
  	@@fiber = nil
  	@@waiting_for_response = false

	  def self.start_new_game(options = {})
			g = Game.new options.merge(:strategy => ConsoleStrategy.new)
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

  class ConsoleStrategy
    def choose(options)
      puts "#{options[:player]}: #{options[:card]} - #{options[:message]}"
      Console.get_response
    end
  end

end
