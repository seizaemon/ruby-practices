#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/shot'

class ShotTest < Minitest::Test

  # test 倒したピンの数を整数で入力するとその数を返す
  # Shot クラスは1投で倒したピンの数を保持するだけの情報管理クラス
  def test_hit_pins
    shot = Shot.new(3)
    assert_equal shot.pins, 3
  end

  # test is_strike?のテスト
  def test_is_strike?
    strike = Shot.new('X')
    not_strike = Shot.new(3)

    assert_equal strike.is_strike?, true
    assert_equal not_strike.is_strike?, false
  end
end