# frozen_string_literal: true

class Frame
  def initialize
    @shots = []
    @shots_max_length = 2
  end

  def strike?
    !@shots[0].nil? and @shots[0].strike?
  end

  def full?
    return true if strike?

    @shots.length == @shots_max_length
  end

  def spare?
    return false if strike?

    score_by_second == 10
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
    @shots.slice(0..nth_shot - 1).map(&:score).sum
  end
end

class LastFrame < Frame
  def initialize
    super
    @shots_max_length = 3
  end

  def full?
    return @shots.length == @shots_max_length if strike? || spare?

    @shots.length == @shots_max_length - 1
  end
end
