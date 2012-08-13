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

  def choose(options)
    @responses.shift
  end
end

def assert_has_a(card_class, list)
	has = list.any? { |c| c.is_a?(card_class) }
	assert has, "Expected list to contain a #{card_class}: #{list}"
end

def assert_has_no(card_class, list)
	has = list.any? { |c| c.is_a?(card_class) }
	assert !has, "Expected list to not contain a #{card_class}: #{list}"
end
