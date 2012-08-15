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

  def done?
    @responses.empty?
  end

  def to_s
    @responses.to_s
  end
end

def respond_with(*args)
  MockStrategy.new(args)
end

def assert_has_a(card_class, list)
	has = list.any? { |c| c.is_a?(card_class) }
	assert has, "Expected list to contain a #{card_class}: #{list.to_a}"
end

def assert_has_count(card_class, list, expected_count)
  actual_count = list.count { |c| c.is_a?(card_class) }
  assert expected_count == actual_count, "Expected list to contain #{expected_count} #{card_class}s: #{list.to_a}"
end

def assert_has_no(card_class, list)
	has = list.any? { |c| c.is_a?(card_class) }
	assert !has, "Expected list to not contain a #{card_class}: #{list.to_a}"
end
