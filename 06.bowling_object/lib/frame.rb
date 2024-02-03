# frozen_string_literal: true

class Frame
  SHOTS_MAX_LENGTH = 2
  SPARE_SCORE = 10
  def initialize
    @shots = []
  end

  def strike?
    !@shots[0].nil? and @shots[0].strike?
  end

  def full?
    strike? ? true : @shots.length == self.class::SHOTS_MAX_LENGTH
  end

  def spare?
    strike? ? false : score_by_second == SPARE_SCORE
  end

  def add_shot(shot)
    @shots << shot unless full?
  end

  def score
    sliced_total_score self.class::SHOTS_MAX_LENGTH
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
