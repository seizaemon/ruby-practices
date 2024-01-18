#!/usr/bin/env ruby

# frozen_string_literal: true
require 'minitest/autorun'
require_relative '../lib/game'
require_relative '../lib/frame'
require_relative '../lib/shot'

class GameTest < Minitest::Test

  def setup
    @game = Game.new
  end

  def create_frames(pins)
    frames = (1..9).map do |s|
      frame = Frame.new
      until frame.is_full?
        frame.add_shot Shot.new(pins.shift)
      end
      frame
    end
    last_frame = LastFrame.new
    # fullの意味が違うことに注意
    until last_frame.is_full?
      last_frame.add_shot Shot.new(pins.shift)
    end
    frames << last_frame
    frames
  end

  # フレーム9個と最終フレーム1個を代入できる
  def test_input_frame
    pins = (1..20).map {|i| 3}
    frames = create_frames(pins)
    frames.each {|f| @game.add_frame(f)}

    frames.each_index {|i| assert @game.frames[i] === frames[i] }
  end


  # ゲームの全てのフレームでスペアが含まれない場合ゲームスコアを正しく計算できる
  def test_total_score_in_normal
    pins = (1..20).map {|i| 3}
    frames = create_frames(pins)
    frames.each {|f| @game.add_frame f}

    # 全て3本ずつ倒すケースを考える  3ピン x 2投 x 10フレーム = 60点
    assert_equal @game.total_score, 60
  end

  # 最終フレームではないところでスペアが含まれる場合ゲームスコアを正しく計算できる
  def test_total_score_in_spare
    pins = [3, 7] + (3..20).map {|i| 3}
    frames = create_frames(pins)
    frames.each {|f| @game.add_frame f}

    # 1フレームのみスペアが含まれるケースの計算
    # 1投目のスコアが 3+7+3=13となるため 13+(3本x2投x9フレーム）= 67
    assert_equal @game.total_score, 67
  end

  # 最終フレームではないところでストライクが含まれる場合ゲームスコアが正しく計算できる
  def test_total_score_in_strike
    pins = ['X'] +(3..20).map {|i| 3}
    frames = create_frames(pins)
    frames.each {|f| @game.add_frame(f)}

    # 1フレームのみストライクが含まれるケースの計算
    # 1投目のスコアが 10+3+3=16となるため 16+(3本x2投x9フレーム）= 70
    assert_equal @game.total_score, 70
  end

  # 最終フレームがスペアの場合ゲームスコアが正しく計算できる
  def test_total_score_in_spare_at_last
    pins = (1..18).map {|i| 3} + [4, 6, 5]
    frames = create_frames(pins)
    frames.each {|f| @game.add_frame(f)}

    # 3ピン x 2投 x 9フレーム + 4 + 6 + 5 = 69
    assert_equal @game.total_score, 69
  end

  # 最終フレームがストライクの場合ゲームスコアが正しく計算できる
  def test_total_score_in_strike_at_last
    pins = (1..18).map {|i| 3} + %w[X X X]
    frames = create_frames(pins)
    frames.each {|f| @game.add_frame f}

    print frames
    # 3ピン x 2投 x 9フレーム + 10 + 10 + 5 = 79
    assert_equal @game.total_score, 79
  end

  # ランダムに生成したピン数でスコアが正しく計算できる
  # 本体のテストと一緒？
end