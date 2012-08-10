class MockGame
  attr_accessor :buy_phase, :actions_in_play

  def buy_phase?
    buy_phase
  end
  
  def durations_in_play
    []
  end
end

class MockStrategy
  def initialize(responses)
    @responses = responses
  end

  def choose(player, options)
    @responses.shift
  end
end

def assert_gained(player, card_class)
	assert player.discard_pile.first.is_a?(card_class), "Expected discard pile to contain a #{card_class}"
end

def assert_has_a(card_class, list)
	has = list.any? { |c| c.is_a?(card_class) }
	assert has, "Expected list to contain a #{card_class}: #{list}"
end
