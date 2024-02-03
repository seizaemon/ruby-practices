# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/game'
require_relative '../lib/last_frame'
require_relative '../lib/shot'

class TestGame < Game
  attr_accessor :frames
end

class GameTest < Minitest::Test
  def setup
    @game = TestGame.new
  end

  def create_frames(pins_ary)
    (1..9).map do
      frame = Frame.new
      frame.add_shot Shot.new(pins_ary.shift) until frame.full?
      frame
    end
  end

  def create_last_frames(pins_ary)
    last_frame = LastFrame.new
    last_frame.add_shot Shot.new(pins_ary.shift) until last_frame.full?
    last_frame
  end

  def fill_pins(num_frames)
    # 3を入れているのはスコア計算をしやすくするため
    (1..num_frames * 2).map { 3 }
  end

  # add_frameはフレーム9個と最終フレーム1個を代入できる
  def test_add_frame
    frames = create_frames(fill_pins(9))
    frames << create_last_frames([3, 3])
    frames.each { |frame| @game.add_frame frame }

    frames.each_index { |i| assert_same @game.frames[i], frames[i] }
  end

  # add_frameはフレーム10個以上は入らない
  def test_add_frame_in_too_much_frames
    frames = create_frames(fill_pins(11))
    frames.each { |frame| @game.add_frame frame }

    (0..9).each { |i| assert_same @game.frames[i], frames[i] }
    assert @game.frames[10].nil?
  end

  # フレーム9個と最終フレーム1個を代入してis_fullがtrueになる
  def test_is_full
    frames = create_frames(fill_pins(9))
    frames << create_last_frames([3, 3])
    frames.each { |frame| @game.add_frame frame }

    assert @game.full?
  end

  # フレームが足りなかったらis_fullがfalseのまま
  def test_is_full_not_fill
    frames = create_frames(fill_pins(9))
    frames.each { |frame| @game.frames << frame }

    assert_equal @game.full?, false
  end
end
