# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/shot'
require_relative '../lib/frame'

class TestLastFrame < LastFrame
  attr_reader :shots
end

class LastFrameTest < Minitest::Test
  def setup
    @last_frame = TestLastFrame.new
  end

  # 2投目まででスペアでない場合is_fullがtrueとなる
  def test_is_full_in_normal
    # 初期値のテスト
    assert_equal @last_frame.is_full?, false
    shots = [
      Shot.new( 2),
      Shot.new(5)
    ]
    shots.each {|s| @last_frame.shots << s}

    assert @last_frame.is_full?
  end

  # 1投目がストライクの場合3投目まで投げてis_fullがtrueになる
  def test_is_full_in_two_strike
    shots = [
      Shot.new('X'),
      Shot.new( 2),
      Shot.new(5)
    ]
    shots.each {|s| @last_frame.shots << s}

    assert @last_frame.is_full?
  end

  # 1投目がストライクの場合2投目までだとis_fullがfalseのまま
  def test_is_full_not_full_in_strike
    shots = [
      Shot.new('X'),
      Shot.new( 2)
    ]
    shots.each {|s| @last_frame.shots << s}

    assert_equal @last_frame.is_full?, false
  end

  # 二投目まででスペアの場合3投まで満たしてis_fullがtrueになる
  def test_is_full_in_spare
    shots = [
      Shot.new(3),
      Shot.new( 7),
      Shot.new(5)
    ]
    shots.each {|s| @last_frame.shots << s}

    assert @last_frame.is_full?
  end

  # 二投目まででスペア場合2投までだとis_fullがfalseのまま
  def test_is_full_not_full_in_spare
    shots = [
      Shot.new(3),
      Shot.new( 7)
    ]
    shots.each {|s| @last_frame.shots << s}

    assert_equal @last_frame.is_full?, false
  end

  # 1投目がストライクの場合3投までshotを受け入れる(add_testのテスト)
  def test_add_shot_accept_three_shot_in_strike
    shots = [
      Shot.new('X'),
      Shot.new( 3),
      Shot.new(5)
    ]
    shots.each {|s| @last_frame.add_shot s}

    assert @last_frame.shots === [shots[0], shots[1], shots[2]]
  end

  # 二投目まででスペアの場合3投までshotを受け入れる(add_testのテスト)
  def test_add_shot_accept_three_shot_in_spare
    shots = [
      Shot.new(3),
      Shot.new( 7),
      Shot.new(5)
    ]
    shots.each {|s| @last_frame.add_shot s}

    assert @last_frame.shots === [shots[0], shots[1], shots[2]]
  end

  # 二投目まででスペアまたはストライクでない場合2投までshotを受け入れる(add_testのテスト)
  def test_add_shot_accept_least_two_shot
    shots = [
      Shot.new(3),
      Shot.new( 6),
      Shot.new(5)
    ]
    shots.each {|s| @last_frame.add_shot(s)}

    assert @last_frame.shots === [shots[0], shots[1]]
  end


  # 2投でスペアの場合はis_spareがtrueとなる
  def test_is_spare
    shots = [
      Shot.new(3),
      Shot.new( 7)
    ]
    shots.each {|s| @last_frame.shots << s}

    assert_equal @last_frame.is_spare?, true
  end

  # 1投目がストライクの場合is_strikeがtrueとなる
  def test_is_full_in_strike
    @last_frame.add_shot Shot.new('X')

    assert_equal @last_frame.is_strike?, true
  end

  # 2投目まででスペアでない場合is_spareはfalseになる
  def test_is_spare_in_not_spare
    shots = [
      Shot.new(1),
      Shot.new( 3)
    ]
    shots.each {|s| @last_frame.shots << s}

    assert_equal @last_frame.is_spare?, false
  end

  # 2投目まででスペアでない場合is_strikeはfalseになる
  def test_is_spare_in_not_strike
    shots = [
      Shot.new(1),
      Shot.new( 3)
    ]
    shots.each {|s| @last_frame.shots << s}

    assert_equal @last_frame.is_strike?, false
  end

  # scoreはスペアの場合2投分の倒したピンの合計を返す
  def test_score
    shots = [
      Shot.new(1),
      Shot.new( 3)
    ]
    shots.each {|s| @last_frame.shots << s}

    assert_equal @last_frame.score, 4
  end

  # scoreは3投分の倒したピンの合計を返す
  def test_score_in_spare
    shots = [
      Shot.new(1),
      Shot.new( 9),
      Shot.new(8)
    ]
    shots.each {|s| @last_frame.shots << s}

    assert_equal @last_frame.score, 18
  end

  # shot_in_firstはShotが3つ入った状態でも一投目に倒したピンの数を返す
  def test_shot_in_first
    shots = [
      Shot.new(1),
      Shot.new( 9),
      Shot.new(8)
    ]
    shots.each {|s| @last_frame.shots << s}

    assert_equal @last_frame.score_at_first, 1
  end

  # shot_by_secondはShotが3つ入った状態でも二本目までに倒したピンの合計を返す
  def test_shot_by_second
    shots = [
      Shot.new(7),
      Shot.new(3),
      Shot.new(8)
    ]
    shots.each {|s| @last_frame.shots << s}

    assert_equal @last_frame.score_by_second, 10
  end
end