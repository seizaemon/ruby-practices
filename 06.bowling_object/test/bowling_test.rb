# frozen_string_literal: true

require 'minitest/autorun'

class BowlingTest < Minitest::Test
  def capture_stdout(arg_string)
    r, w = IO.pipe
    system "ruby ../bowling.rb #{arg_string}", chdir: __dir__, out: w
    w.close
    r.gets.to_i
  end

  # ゲームの全てのフレームでスペアが含まれない場合ゲームスコアを正しく計算できる
  def test_total_score_in_normal
    pins = (0..20).map { 3 }.join(',')

    # 全て3本ずつ倒すケースを考える  3ピン x 2投 x 10フレーム = 60点
    assert_equal 60, capture_stdout(pins)
  end

  # 最終フレームではないところでスペアが含まれる場合ゲームスコアを正しく計算できる
  def test_total_score_in_spare
    pins = ([1, 9] + (3..20).map { 3 }).join(',')

    # 1フレームのみスペアが含まれるケースの計算
    # 1投目のスコアが 3+7+3=13となるため 13+(3本x2投x9フレーム）= 67
    assert_equal 67, capture_stdout(pins)
  end

  # 最終フレームではないところでストライクが含まれる場合ゲームスコアが正しく計算できる
  def test_total_score_in_strike
    pins = (['X'] + (3..20).map { 3 }).join(',')

    # 1フレームのみストライクが含まれるケースの計算
    # 1投目のスコアが 10+3+3=16となるため 16+(3本x2投x9フレーム）= 70
    assert_equal 70, capture_stdout(pins)
  end

  # 最終フレームがスペアの場合ゲームスコアが正しく計算できる
  def test_score_in_spare_at_last
    pins = ((1..18).map { 3 } + [4, 6, 5]).join(',')

    # 3ピン x 2投 x 9フレーム + 4 + 6 + 5 = 69
    assert_equal 69, capture_stdout(pins)
  end

  # 最終フレームがストライクの場合ゲームスコアが正しく計算できる
  def test_score_in_strike_at_last
    pins = ((1..18).map { 3 } + ['X', 'X', 5]).join(',')

    # 3ピン x 2投 x 9フレーム + 10 + 10 + 5 = 84
    assert_equal 79, capture_stdout(pins)
  end

  # ストライクが2回連続した場合にゲームスコアが正しく計算できる
  def test_score_in_continuous_strike
    pins = (['X', 'X', 5, 3] + (5..20).map { 3 }).join(',')

    # フレーム1: 10+10+5=25 フレーム2: 10+5+3=18 フレーム3: 5+3=8 残り 3x2x7=42 合計93
    assert_equal 93, capture_stdout(pins)
  end

  # 最終フレーム前にストライクが2回連続した場合にゲームスコアが正しく計算できる
  def test_score_in_continuous_strike_before_last
    pins = ((1..16).map { 3 } + ['X', 'X', 5, 5]).join(',')

    # フレーム9: 10+10+5=25 フレーム10: 10+5+5=20 残り 3x2x8=48 合計93
    assert_equal 93, capture_stdout(pins)
  end
end
