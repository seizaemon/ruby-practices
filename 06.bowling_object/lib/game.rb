# frozen_string_literal: true

class Game
  def initialize
    @frames = []
    @frames_max_length = 10
  end

  def add_frame(frame)
    @frames << frame unless full?
  end

  def score
    (0..@frames.length - 1).map do |i|
      if i == @frames_max_length - 1
        @frames[i].score
      elsif @frames[i].spare?
        score_in_spare(i)
      elsif @frames[i].strike?
        score_in_strike(i)
      else
        @frames[i].score
      end
    end.sum
  end

  def full?
    @frames.length == @frames_max_length
  end

  private

  def score_in_spare(frame_index)
    nil if frame_index == 9
    nil unless @frames[frame_index].spare?
    @frames[frame_index].score + @frames[frame_index + 1].score_at_first
  end

  def score_in_strike(frame_index)
    nil if frame_index == 9
    nil unless @frames[frame_index].strike?

    if @frames[frame_index + 1].strike? && frame_index < 8
      [
        @frames[frame_index].score,
        @frames[frame_index + 1].score,
        @frames[frame_index + 2].score_at_first
      ].sum
    else
      [
        @frames[frame_index].score,
        @frames[frame_index + 1].score_by_second
      ].sum
    end
  end
end
