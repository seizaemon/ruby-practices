#!/usr/bin/env ruby

# frozen_string_literal: true
require 'minitest/autorun'
require 'stringio'



class BowlingTest < Minitest::Test

  def capture_stdout(args)
    r, w = IO.pipe
    system "ruby ../bowling.rb #{args}", :chdir=>__dir__, :out=>w
    w.close
    r.gets.to_i
  end

  # 適当に生成したボーリングのスコア表から正しいスコアを計算する
  def test_bowling_score_pattern1
    args = '6,3,9,0,0,3,8,2,7,3,X,9,1,8,0,X,6,4,5'

    assert_equal 139, capture_stdout(args)
  end

  def test_bowling_score_pattern2
    args = '6,3,9,0,0,3,8,2,7,3,X,9,1,8,0,X,X,X,X'

    assert_equal 164, capture_stdout(args)
  end

  def test_bowling_score_pattern3
    args = '0,10,1,5,0,0,0,0,X,X,X,5,1,8,1,0,4'

    assert_equal 107, capture_stdout(args)
  end

  def test_bowling_score_pattern4
    args = '6,3,9,0,0,3,8,2,7,3,X,9,1,8,0,X,X,0,0'

    assert_equal 134, capture_stdout(args)
  end

  def test_bowling_score_pattern5
    args = '6,3,9,0,0,3,8,2,7,3,X,9,1,8,0,X,X,1,8'

    assert_equal 144, capture_stdout(args)
  end

  def test_bowling_score_pattern6
    args = 'X,X,X,X,X,X,X,X,X,X,X,X'

    assert_equal 300, capture_stdout(args)
  end

  def test_bowling_score_pattern7
    args = 'X,X,X,X,X,X,X,X,X,X,X,2'

    assert_equal 292, capture_stdout(args)
  end

  def test_bowling_score_pattern8
    args = 'X,0,0,X,0,0,X,0,0,X,0,0,X,0,0'

    assert_equal 50, capture_stdout(args)
  end
end