# frozen_string_literal: true

class Shot
  attr_reader :pins

  def initialize(pins)
    @pins = pins
  end

  def is_strike?
    @pins == 'X'
  end
end

