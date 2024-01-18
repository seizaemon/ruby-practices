# frozen_string_literal: true

class Game
  attr_reader :frames
  def initialize
    @frames = Array.new
  end

  def add_frame(frame)
    @frames << frame unless self.is_full?
  end

  def total_score
    (0..@frames.length-1).map do |i|
      if i == 9
        @frames[i].total
      elsif @frames[i].is_spare?
        self.score_in_spare(i)
      elsif @frames[i].is_strike?
        self.score_in_strike(i)
      else
        @frames[i].total
      end
    end.sum
  end

  private

  def score_in_spare(frame_index)
    nil unless @frames[frame_index].is_spare?
    @frames[frame_index].total + @frames[frame_index+1].shot_in_first
  end

  def score_in_strike(frame_index)
    nil unless @frames[frame_index].is_strike?
    @frames[frame_index].total + @frames[frame_index+1].shot_by_second
  end

  private

  def is_full?
    @frames.length == 10
  end
end