# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/shot'

class ShotTest < Minitest::Test
  def setup
    @shot_normal = Shot.new('3')
    @shot_strike = Shot.new('X')
  end

  # scoreはピンの数を返す
  def test_score
    assert_equal @shot_normal.score, 3
  end

  # ストライクの場合scoreは10を返す
  def test_score_in_strike
    assert_equal @shot_strike.score, 10
  end

  # ストライクの際is_strike?はtrueを返す
  def test_is_strike
    assert @shot_strike.is_strike?
  end

  #ストライクでない場合is_strike?はfalseを返す
  def test_is_strike_in_not_strike
    assert_equal @shot_normal.is_strike?, false
  end
end