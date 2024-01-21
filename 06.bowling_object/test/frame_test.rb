# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/shot'
require_relative '../lib/frame'

class TestFrame < Frame
  attr_accessor :shots
end

class FrameTest < Minitest::Test

  def setup
    @frame = TestFrame.new
  end

  # add_shotはShotオブジェクトをFrameオブジェクトに順に追加する
  def test_add_shot
    shots = [
      Shot.new(6),
      Shot.new(3)
    ]

    @frame.add_shot shots[0]
    assert @frame.shots[0] === shots[0]
    @frame.add_shot shots[1]
    assert @frame.shots[1] === shots[1]
  end

  # add_shotは2投以上は受け入れない
  def test_add_shot_in_too_much_shots
    shots = [
      Shot.new(6),
      Shot.new(3),
      Shot.new(1)
    ]
    shots.each {|s| @frame.add_shot s}

    assert @frame.shots[0] === shots[0]
    assert @frame.shots[1] === shots[1]
    assert @frame.shots[2].nil?
  end

  # add_shotは1投目がストライクの場合それ以上Shotオブジェクトを受け入れない
  def test_add_shot_in_strike
    shots = [
      Shot.new('X'),
      Shot.new(3)
    ]
    shots.each {|s| @frame.add_shot s}

    assert @frame.shots[0] === shots[0]
    assert @frame.shots[1].nil?
  end

  # 1投目がストライクの場合のis_full?がtrueを返す
  def test_is_full_in_strike
    @frame.shots << Shot.new('X')

    assert_equal @frame.is_full?, true
  end

  # 1投目がストライクでなく2投目まで投げた場合is_full?はtrueを返す
  def test_is_full
    shots = [
      Shot.new(7),
      Shot.new(2)
    ]
    shots.each {|s| @frame.shots << s}

    assert_equal @frame.is_full?, true
  end

  # 一投目がストライクでない場合is_full?はfalseになる
  def test_is_not_full
    @frame.shots << Shot.new(6)

    assert_equal @frame.is_full?, false
  end

  # フレームがストライク（1投目ストライク）の場合is_strike?はtrueになる
  def test_is_strike
    @frame.shots << Shot.new('X')

    assert_equal @frame.is_strike?, true
  end

  # フレームがストライクでない場合is_strike?はfalseを返す
  def test_is_strike_in_not_strike
    shots = [
      Shot.new(8),
      Shot.new(1)
    ]
    shots.each {|s| @frame.shots << s}

    assert_equal @frame.is_strike?, false
  end

  # フレームがスペアの際is_spare?はtrueを返す
  def test_is_spare_in_spare
    shots = [
      Shot.new(7),
      Shot.new(3)
    ]
    shots.each {|s| @frame.shots << s}

    assert_equal @frame.is_spare?, true
  end

  # フレームがスペアでない場合is_spare?はfalseになる
  def test_is_spare_in_normal
    shots = [
      Shot.new(6),
      Shot.new(3)
    ]
    shots.each {|s| @frame.shots << s}

    assert_equal @frame.is_spare?, false
  end

  # フレームがストライクの場合is_spare?はfalseになる
  def test_is_spare_in_strike
    @frame.shots << Shot.new('X')

    assert_equal @frame.is_spare?, false
  end

  # scoreは倒したピンの合計を返す
  def test_score
    shots = [
      Shot.new(5),
      Shot.new(3)
    ]
    shots.each {|s| @frame.shots << s}

    assert_equal @frame.score, 8
  end

  # フレームがストライクの場合scoreは10を返す
  def test_total_in_strike
    @frame.shots << Shot.new('X')

    assert_equal @frame.score, 10
  end

  # score_at_firstは一本目で倒したピンの数を返す
  def test_score_at_first
    shots = [
      Shot.new(7),
      Shot.new(2)
    ]
    shots.each {|s| @frame.shots << s}

    assert_equal @frame.score_at_first, 7
  end

  # shot_by_secondは二本目までに倒したピンの合計を返す
  def test_shot_by_second
    shots = [
      Shot.new(7),
      Shot.new(2)
    ]
    shots.each {|s| @frame.shots << s}

    assert_equal @frame.score_by_second, 9
  end
end