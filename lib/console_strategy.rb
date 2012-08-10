require 'fiber'

module Dominion

  class ConsoleStrategy
  	@@fiber = nil
  	@@waiting_for_response = false

    def choose(player, options)
      puts "#{player}: #{player.card_in_play} - #{options[:message]}"
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
  	ConsoleStrategy.waiting_for_response?
  end

  def respond(value)
  	ConsoleStrategy.respond(value)
  end

end
