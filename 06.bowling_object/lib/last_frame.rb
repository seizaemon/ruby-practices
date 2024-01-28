# frozen_string_literal: true

require_relative 'frame'
class LastFrame < Frame
  MAX_SHOT = 3

  def initialize
    super
    @shots_max_length = MAX_SHOT
  end

  def full?
    return @shots.length == @shots_max_length if strike? || spare?

    @shots.length == @shots_max_length - 1
  end
end
