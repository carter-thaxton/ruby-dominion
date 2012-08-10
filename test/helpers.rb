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

