# frozen_string_literal: true

class Frame
  def initialize
    @shots = Array.new
    @shots_max_length = 2
  end

  def is_strike?
    @shots.length == @shots_max_length-1 and @shots.map {|shot| shot.is_strike?}.all?
  end

  def is_full?
    return true if self.is_strike?
    @shots.length == @shots_max_length
  end

  def is_spare?
    return false if self.is_strike?
    self.total_by_second == 10
  end

  def add_shot(shot)
    @shots << shot unless self.is_full?
  end

  def total
    slice_total_score @shots_max_length
  end

  def first_score
    slice_total_score 1
  end

  def total_by_second
    slice_total_score 2
  end

  private

  def slice_total_score(nth_shot)
    @shots.slice(0..nth_shot-1).map {|shot| shot.score }.sum
  end
end

class LastFrame < Frame
  def initialize
    super
    @shots_max_length = 3
  end

  def is_full?
    if self.is_strike? or self.is_spare?
      true if @shots.length == @shots_max_length
    else
      true if @shots.length == @shots_max_length-1
    end
  end
end