# frozen_string_literal: true

require_relative 'frame'
class LastFrame < Frame
  SHOTS_MAX_LENGTH = 3

  def full?
    return @shots.length == self.class::SHOTS_MAX_LENGTH if strike? || spare?

    @shots.length == self.class::SHOTS_MAX_LENGTH - 1
  end
end
