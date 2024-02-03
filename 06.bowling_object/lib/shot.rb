# frozen_string_literal: true

class Shot
  STRIKE = 'X'
  STRIKE_PINS = 10
  def initialize(pins)
    @pins = convert(pins)
  end

  def strike?
    @pins == STRIKE_PINS
  end

  def score
    @pins
  end

  private

  def convert(pins)
    pins == STRIKE ? STRIKE_PINS : pins.to_i
  end
end
