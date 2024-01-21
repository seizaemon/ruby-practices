# frozen_string_literal: true

require 'minitest/autorun'

class BowlingTest < Minitest::Test
  def capture_stdout(arg_string)
    r, w = IO.pipe
    system "ruby ../bowling.rb #{arg_string}", chdir: __dir__, out: w
    w.close
    r.gets.to_i
  end

  # 課題にあった倒したピンの引数からスコアが正しく計算できる
  def test_bowling_score_pattern1
    pins = '6,3,9,0,0,3,8,2,7,3,X,9,1,8,0,X,6,4,5'

    assert_equal 139, capture_stdout(pins)
  end

  def test_bowling_score_pattern2
    pins = '6,3,9,0,0,3,8,2,7,3,X,9,1,8,0,X,X,X,X'

    assert_equal 164, capture_stdout(pins)
  end

  def test_bowling_score_pattern3
    pins = '0,10,1,5,0,0,0,0,X,X,X,5,1,8,1,0,4'

    assert_equal 107, capture_stdout(pins)
  end

  def test_bowling_score_pattern4
    pins = '6,3,9,0,0,3,8,2,7,3,X,9,1,8,0,X,X,0,0'

    assert_equal 134, capture_stdout(pins)
  end

  def test_bowling_score_pattern5
    pins = '6,3,9,0,0,3,8,2,7,3,X,9,1,8,0,X,X,1,8'

    assert_equal 144, capture_stdout(pins)
  end

  def test_bowling_score_pattern6
    pins = 'X,X,X,X,X,X,X,X,X,X,X,X'

    assert_equal 300, capture_stdout(pins)
  end

  def test_bowling_score_pattern7
    pins = 'X,X,X,X,X,X,X,X,X,X,X,2'

    assert_equal 292, capture_stdout(pins)
  end

  def test_bowling_score_pattern8
    pins = 'X,0,0,X,0,0,X,0,0,X,0,0,X,0,0'

    assert_equal 50, capture_stdout(pins)
  end
end
