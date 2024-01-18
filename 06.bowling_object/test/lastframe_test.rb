#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/shot'
require_relative '../lib/frame'

class TestLastFrame < LastFrame
  attr_reader :shots
  attr_writer :shots
end

class LastFrameTest < Minitest::Test
  def setup
    @last_frame = TestLastFrame.new
  end

  # 2投目まで連続ストライクの場合3投目も投げてis_fullがtrueになる
  def test_is_full_in_two_strike
    shots = [
      Shot.new('X'),
      Shot.new( 'X'),
      Shot.new(5)
    ]
    shots.each {|s| @last_frame.shots << s}

    print @last_frame.is_strike?
    print @last_frame.is_spare?

    assert @last_frame.is_full?
  end

  # 二投目まででスペア場合3投まで満たしてis_fullがtrueになる
  def test_is_full_in_spare
    shots = [
      Shot.new(3),
      Shot.new( 7),
      Shot.new(5)
    ]
    shots.each {|s| @last_frame.shots << s}

    assert @last_frame.is_full?
  end

  # 二投目まで連続でストライクの場合3投までshotを受け入れる(add_testのテスト)
  def test_accept_three_shot_in_strike
    shots = [
      Shot.new('X'),
      Shot.new( 'X'),
      Shot.new(5)
    ]
    shots.each {|s| @last_frame.add_shot(s)}

    assert @last_frame.shots === [shots[0], shots[1], shots[2]]
  end

  # 二投目まででスペアの場合3投までshotを受け入れる(add_testのテスト)
  def test_accept_three_shot_in_spare
    shots = [
      Shot.new(3),
      Shot.new( 7),
      Shot.new(5)
    ]
    shots.each {|s| @last_frame.add_shot(s)}

    assert @last_frame.shots === [shots[0], shots[1], shots[2]]
  end

  # 二投目まででスペアまたはストライクでない場合2投までshotを受け入れる(add_testのテスト)
  def test_accept_least_two_shot
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

    assert_equal @last_frame.first_score, 1
  end

  # shot_by_secondは二本目までに倒したピンの合計を返す
  def test_shot_by_second
    shots = [
      Shot.new(7),
      Shot.new(3),
      Shot.new(8)
    ]
    shots.each {|s| @last_frame.add_shot(s)}

    assert_equal @last_frame.total_by_second, 10
  end
end