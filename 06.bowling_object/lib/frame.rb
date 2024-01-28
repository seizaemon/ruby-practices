# frozen_string_literal: true

class Frame
  MAX_SHOT = 2
  SPARE_SCORE = 10
  def initialize
    @shots = []
    @shots_max_length = MAX_SHOT
  end

  def strike?
    !@shots[0].nil? and @shots[0].strike?
  end

  def full?
    strike? ? true : @shots.length == @shots_max_length
  end

  def spare?
    strike? ? false : score_by_second == SPARE_SCORE
  end

  def add_shot(shot)
    @shots << shot unless full?
  end

  def score
    sliced_total_score @shots_max_length
  end

  def score_at_first
    sliced_total_score 1
  end

  def score_by_second
    sliced_total_score 2
  end

  private

  def sliced_total_score(nth_shot)
    @shots.slice(0..nth_shot - 1).sum(&:score)
  end
end
