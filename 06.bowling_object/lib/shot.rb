# frozen_string_literal: true

class Shot
  def initialize(pins)
    @pins = convert(pins)
  end

  def is_strike?
    @pins == 10
  end

  def to_i
    @pins
  end

  private
  def convert(pins)
    return 10 if pins == 'X'
    pins.to_i
  end
end

