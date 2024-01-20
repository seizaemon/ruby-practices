# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/game'
require_relative '../lib/frame'
require_relative '../lib/shot'

class TestGame < Game
  attr_reader :frames
end

class GameTest < Minitest::Test

  def setup
    @game = TestGame.new
  end

  def create_frames(pins)
    (1..9).map do
      frame = Frame.new
      until frame.is_full?
        frame.add_shot Shot.new(pins.shift)
      end
      frame
    end
  end

  def create_last_frames(pins)
    last_frame = LastFrame.new
    until last_frame.is_full?
      last_frame.add_shot Shot.new(pins.shift)
    end
    last_frame
  end

  # ３が入った配列をフレーム数要素分作成
  def fill_pins(num_frames)
    (1..num_frames*2).map { 3 }
  end

  # フレーム9個と最終フレーム1個を代入できる
  def test_input_frame
    frames = create_frames(fill_pins(9))
    frames << create_last_frames([3,3])
    frames.each {|frame| @game.add_frame(frame)}

    frames.each_index {|i| assert @game.frames[i] === frames[i] }
  end

  # フレーム9個と最終フレーム1個を代入してis_fullがtrueになる
  def test_is_full
    frames = create_frames(fill_pins(9))
    frames << create_last_frames([3,3])
    frames.each {|frame| @game.add_frame(frame)}

    assert @game.is_full?
  end

  # フレームが足りなかったらis_fullがfalseのまま
  def test_is_full_not_fill
    frames = create_frames(fill_pins(9))
    frames.each {|frame| @game.add_frame(frame)}

    assert_equal @game.is_full?, false
  end

  # ゲームの全てのフレームでスペアが含まれない場合ゲームスコアを正しく計算できる
  def test_total_score_in_normal
    frames = create_frames(fill_pins(9))
    frames << create_last_frames([3,3])
    frames.each {|f| @game.add_frame f}

    # 全て3本ずつ倒すケースを考える  3ピン x 2投 x 10フレーム = 60点
    assert_equal @game.score, 60
  end

  # 最終フレームではないところでスペアが含まれる場合ゲームスコアを正しく計算できる
  def test_total_score_in_spare
    frames = create_frames([3, 7] + fill_pins(8))
    frames << create_last_frames([3,3])
    frames.each {|f| @game.add_frame f}

    # 1フレームのみスペアが含まれるケースの計算
    # 1投目のスコアが 3+7+3=13となるため 13+(3本x2投x9フレーム）= 67
    assert_equal @game.score, 67
  end

  # 最終フレームではないところでストライクが含まれる場合ゲームスコアが正しく計算できる
  def test_total_score_in_strike
    frames = create_frames(['X'] + fill_pins(8))
    frames << create_last_frames([3,3])
    frames.each {|f| @game.add_frame(f)}

    # 1フレームのみストライクが含まれるケースの計算
    # 1投目のスコアが 10+3+3=16となるため 16+(3本x2投x9フレーム）= 70
    assert_equal @game.score, 70
  end

  # 最終フレームがスペアの場合ゲームスコアが正しく計算できる
  def test_score_in_spare_at_last
    frames = create_frames(fill_pins(9))
    frames << create_last_frames([4, 6, 5])
    frames.each {|f| @game.add_frame(f)}

    # 3ピン x 2投 x 9フレーム + 4 + 6 + 5 = 69
    assert_equal @game.score, 69
  end

  # 最終フレームがストライクの場合ゲームスコアが正しく計算できる
  def test_score_in_strike_at_last
    frames = create_frames(fill_pins(9))
    frames << create_last_frames(%w[X X X])
    frames.each {|f| @game.add_frame f}

    # 3ピン x 2投 x 9フレーム + 10 + 10 + 10 = 84
    assert_equal @game.score, 84
  end

  # ストライクが2回連続した場合にゲームスコアが正しく計算できる
  def test_score_in_continuous_strike
    frames = create_frames(['X', 'X', 5, 3] + fill_pins(6))
    frames << create_last_frames([3,3])
    frames.each {|f| @game.add_frame f}

    # フレーム1: 10+10+5=25 フレーム2: 10+5+3=18 フレーム3: 5+3=8 残り 3x2x7=42 合計93
    assert_equal @game.score, 93
  end

  # 最終フレーム前にストライクが2回連続した場合にゲームスコアが正しく計算できる
  def test_score_in_continuous_strike_before_last
    frames = create_frames(fill_pins(8) + ['X'])
    frames << create_last_frames(['X', 5, 5])
    frames.each {|f| @game.add_frame f}

    # フレーム9: 10+10+5=25 フレーム10: 10+5+5=20 残り 3x2x8=48 合計93
    assert_equal @game.score, 93
  end
end