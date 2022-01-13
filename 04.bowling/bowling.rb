#!/usr/bin/env ruby
# frozen_string_literal: true

# フレームを分ける
def divide_frame(history)
  frames = Array.new(10)

  (0..9).each do |i|
    # 最終フレームは残り全てを詰め込むのみ
    if i == 9
      frames[i] = history.map { |n| n == 'X' ? 10 : n.to_i }
    elsif history.first == 'X'
      frames[i] = [10]
      history.shift
    else
      frames[i] = [history.shift.to_i, history.shift.to_i]
    end
  end

  frames
end

def calc_score(frames)
  score = []
  frames.each_with_index do |frame, idx|
    # 最終フレーム
    if idx == 9
      score.push(frame.sum)
    # ストライク
    elsif frame[0] == 10
      score.push(10 + sum_of_next_scores(frames, idx, throws: 2))
    # スペア
    elsif frame.sum == 10
      score.push(frame.sum + sum_of_next_scores(frames, idx))
    else
      score.push(frame.sum)
    end
  end
  score.sum
end

# 指定したフレームから次のthrow分の合計スコアを返す
def sum_of_next_scores(frames, index, throws: 1)
  last_part_of_frames = frames.slice(index + 1..frames.size)
  last_part_of_frames.flatten.slice(0..throws - 1).sum
end

score_history = ARGV[0].split(',')
frames = divide_frame(score_history)
puts calc_score(frames)
