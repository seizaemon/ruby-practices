# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/shot'
require_relative '../lib/frame'

class TestFrame < Frame
  attr_reader :shots
end

class FrameTest < Minitest::Test

  def setup
    @frame = TestFrame.new
  end

  # add_shotはShotオブジェクトをFrameオブジェクトに追加する
  def test_add_shot
    shot = Shot.new 6
    @frame.add_shot shot

    assert @frame.shots[0] === shot
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
    shots.each {|s| @frame.add_shot(s)}

    assert_equal @frame.is_full?, true
  end

  # 一投目がストライクでない場合is_full?はfalseになる
  def test_is_not_full
    @frame.shots << Shot.new(6)

    assert_equal @frame.is_full?, false
  end

  # フレームがストライク（1投目ストライク）の場合is_strike?はtrueになる
  def test_is_strike?
    @frame.add_shot Shot.new('X')

    assert_equal @frame.is_strike?, true
  end

  # フレームがストライクでない場合is_strike?はfalseを返す
  def test_not_is_strike
    shots = [
      Shot.new(8),
      Shot.new(1)
    ]
    shots.each {|s| @frame.add_shot(s)}

    assert_equal @frame.is_strike?, false
  end

  # フレームがスペアの際is_spare?はtrueを返す
  def test_is_spare_in_spare
    shots = [
      Shot.new(7),
      Shot.new(3)
    ]
    shots.each {|s| @frame.add_shot(s)}

    assert_equal @frame.is_spare?, true
  end

  # フレームがスペアでなくストライクでもない場合is_spare?はfalseになる
  def test_is_spare_in_normal
    shots = [
      Shot.new( 6),
      Shot.new(3)
    ]
    shots.each {|s| @frame.add_shot(s)}

    assert_equal @frame.is_spare?, false
  end

  # フレームがスペアでなくストライクでもない場合is_strike?はfalseになる
  def test_is_strike_in_normal
    shots = [
      Shot.new( 6),
      Shot.new(3)
    ]
    shots.each {|s| @frame.add_shot(s)}

    assert_equal @frame.is_strike?, false
  end

  # フレームがストライクの場合is_spare?はfalseになる
  def test_is_spare_in_strike
    @frame.add_shot Shot.new('X')

    assert_equal @frame.is_spare?, false
  end

  # totalは倒したピンの合計を返す
  def test_score
    shots = [
      Shot.new(5),
      Shot.new(3)
    ]
    shots.each {|s| @frame.add_shot(s)}

    assert_equal @frame.score, 8
  end

  # フレームがストライクの場合total_pinsは10を返す
  def test_total_in_strike
    @frame.add_shot Shot.new('X')

    assert_equal @frame.score, 10
  end

  # score_at_firstは一本目で倒したピンの数を返す
  def test_score_at_first
    shots = [
      Shot.new(7),
      Shot.new(2)
    ]
    shots.each {|s| @frame.add_shot(s)}

    assert_equal @frame.score_at_first, 7
  end

  # shot_by_secondは二本目までに倒したピンの合計を返す
  def test_shot_by_second
    shots = [
      Shot.new(7),
      Shot.new(2)
    ]
    shots.each {|s| @frame.add_shot(s)}

    assert_equal @frame.score_by_second, 9
  end
end