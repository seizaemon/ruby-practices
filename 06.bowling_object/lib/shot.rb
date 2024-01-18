# frozen_string_literal: true

class Shot
  def initialize(pins)
    @pins = convert(pins)
    @max_pins = 10
  end

  def is_strike?
    @pins == 10
  end

  def score
    @pins
  end

  def remain
    @max_pins - @pins
  end

  private
  def convert(pins)
    return 10 if pins == 'X'
    pins
  end
end

