#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/shot'
require_relative '../lib/frame'


class FrameTest < Minitest::Test

  def setup
    @frame = Frame.new
  end

  # 1投目がストライクで無い場合のadd_shotのテスト
  def test_shots_in_not_strike_frame
    shots = [
      Shot.new( 8),
      Shot.new( 1)
    ]
    @frame.add_shot shots[0]
    assert @frame.shots === { first: shots[0], second: nil }

    @frame.add_shot shots[1]
    assert @frame.shots === { first: shots[0], second: shots[1] }
  end

  # 1投目がストライクの場合のadd_shotでshotを追加しても無視される
  def test_shots_in_strike_frame
    shots = [
      Shot.new('X'),
      Shot.new(3)
    ]
    @frame.add_shot shots[0]
    assert @frame.shots === { first: shots[0], second: nil }

    # 本当はエラーにしたい（コレ必要だろうか）
    @frame.add_shot shots[1]
    assert @frame.shots === { first: shots[0], second: nil }
  end

  # フレームがストライクの場合is_strike?はtrueになる
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

  # フレームがストライクの場合is_spare?はfalseになる
  def test_is_spare_in_strike
    @frame.add_shot Shot.new('X')

    assert_equal @frame.is_spare?, false
  end

  # 1投目がストライクの場合のis_full?がtrueを返す
  def test_is_full_in_strike
    @frame.add_shot Shot.new('X')

    assert_equal @frame.is_full?, true
  end

  # 二投目まで投げた場合is_full?はtrueを返す
  def test_is_full?
    shots = [
      Shot.new(7),
      Shot.new(2)
    ]
    shots.each {|s| @frame.add_shot(s)}

    assert_equal @frame.is_full?, true
  end

  # 一投目がストライクでない場合is_full?はfalseになる
  def test_is_not_full
    @frame.add_shot Shot.new(6)

    assert_equal @frame.is_full?, false
  end

  # totalは倒したピンの合計を返す
  def test_total
    shots = [
      Shot.new(5),
      Shot.new(3)
    ]
    shots.each_index {|i, s| @frame.add_shot(shots[i])}

    assert_equal @frame.total, 8
  end

  # フレームがストライクの場合total_pinsは10を返す
  def test_total_in_strike
    @frame.add_shot Shot.new('X')

    assert_equal @frame.total, 10
  end

  # shot_in_firstは一本目で倒したピンの数を返す
  def test_shot_in_first
    shots = [
      Shot.new(7),
      Shot.new(2)
    ]
    shots.each {|s| @frame.add_shot(s)}

    assert_equal @frame.shot_in_first, 7
  end

  # shot_by_secondは二本目までに倒したピンの合計を返す
  def test_shot_by_second
    shots = [
      Shot.new(7),
      Shot.new(2)
    ]
    shots.each {|s| @frame.add_shot(s)}

    assert_equal @frame.shot_in_first, 7
  end
end

class LastFrameTest < Minitest::Test
  def setup
    @last_frame = LastFrame.new
  end

  # 二投目まで連続でストライクの場合3投までshotを受け入れる(add_testのテスト)
  def test_accept_three_shot_in_strike
    shots = [
      Shot.new('X'),
      Shot.new( 'X'),
      Shot.new(5)
    ]
    shots.each {|s| @last_frame.add_shot(s)}

    assert @last_frame.shots[:first] === shots[0]
    assert @last_frame.shots[:second] === shots[1]
    assert @last_frame.shots[:third] === shots[2]
  end

  # 二投目まででスペアの場合3投までshotを受け入れる(add_testのテスト)
  def test_accept_three_shot_in_spare
    shots = [
      Shot.new(3),
      Shot.new( 7),
      Shot.new(5)
    ]
    shots.each {|s| @last_frame.add_shot(s)}

    assert @last_frame.shots[:first] === shots[0]
    assert @last_frame.shots[:second] === shots[1]
    assert @last_frame.shots[:third] === shots[2]
  end

  # 二投目まででスペアまたはストライクでない場合2投までshotを受け入れる(add_testのテスト)
  def test_accept_least_two_shot
    shots = [
      Shot.new(3),
      Shot.new( 6),
      Shot.new(5)
    ]
    shots.each {|s| @last_frame.add_shot(s)}

    assert @last_frame.shots[:first] === shots[0]
    assert @last_frame.shots[:second] === shots[1]
    assert_nil @last_frame.shots[:third]
  end


  # 2投でスペアの場合はis_spareがtrueとなる
  def test_is_spare
    shots = [
      Shot.new(3),
      Shot.new( 7)
    ]
    [0,1].each {|i| @last_frame.add_shot(shots[i])}

    assert_equal @last_frame.is_spare?, true
  end

  # 1投目2投目がストライクの場合is_strikeがtrueとなる
  def test_is_full_in_strike
    shots = [
      Shot.new('X'),
      Shot.new( 'X')
    ]
    [0,1].each {|i| @last_frame.add_shot(shots[i])}

    assert_equal @last_frame.is_strike?, true
  end

  # 2投目まででスペアでない場合is_spareはfalseになる
  def test_is_spare_in_not_spare
    shots = [
      Shot.new(1),
      Shot.new( 3)
    ]
    [0,1].each {|i| @last_frame.add_shot(shots[i])}

    assert_equal @last_frame.is_spare?, false
  end

  # 2投目まででスペアでない場合is_strikeはfalseになる
  def test_is_spare_in_not_strike
    shots = [
      Shot.new(1),
      Shot.new( 3)
    ]
    [0,1].each {|i| @last_frame.add_shot(shots[i])}

    assert_equal @last_frame.is_strike?, false
  end

  # totalはスペアでない場合2投分の倒したピンの合計を返す
  def test_total
    shots = [
      Shot.new(1),
      Shot.new( 3)
    ]
    shots.each {|s| @last_frame.add_shot(s)}

    assert_equal @last_frame.total, 4
  end

  # totalはスペアの場合3投分の倒したピンの合計を返す
  def test_total_in_spare
    shots = [
      Shot.new(1),
      Shot.new( 9),
      Shot.new(8)
    ]
    shots.each {|s| @last_frame.add_shot(s)}

    assert_equal @last_frame.total, 18
  end

  # shot_in_firstは一投目に倒したピンの数を返す
  def test_shot_in_first
    shots = [
      Shot.new(1),
      Shot.new( 9),
      Shot.new(8)
    ]
    shots.each {|s| @last_frame.add_shot(s)}

    assert_equal @last_frame.shot_in_first, 1
  end

  # shot_by_secondは二本目までに倒したピンの合計を返す
  def test_shot_by_second
    shots = [
      Shot.new(7),
      Shot.new(3),
      Shot.new(8)
    ]
    shots.each {|s| @last_frame.add_shot(s)}

    assert_equal @last_frame.shot_by_second, 10
  end
end