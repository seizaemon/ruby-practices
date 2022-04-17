#!/usr/bin/env ruby

# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/wc'

class WcSimpleTest < Minitest::Test
  def setup
    input = <<~TEXT
      test1 test2
      test3
    TEXT
    @test_wc = Wc.new(input)
  end

  def test_count_line
    expected = 2
    assert_equal expected, @test_wc.lines
  end

  def test_count_word
    expected = 3
    assert_equal expected, @test_wc.words
  end

  def test_count_byte
    expected = 18
    assert_equal expected, @test_wc.bytes
  end
end

class WcComplexTest < Minitest::Test
  def test_count_case1
    input = <<~TEXT
      drwxr-xr-x  6 oden  staff  192  4 16 17:42 wctest
    TEXT
    test_wc = Wc.new(input)
    expected = '       1       9      50'
    assert_equal expected, test_wc.output
  end

  def test_count_case2
    input = <<~TEXT
      total 0
      -rw-r--r--  1 oden  staff    0  2 19 23:11 test1
      -rw-r--r--  1 oden  staff    0  2 19 23:11 test2
      -rw-r--r--  1 oden  staff    0  2 19 23:11 test3
      drwxr-xr-x  6 oden  staff  192  2 23 17:53 test_dir1
      drwxr-xr-x  4 oden  staff  128  2 23 17:53 test_dir2
      drwxr-xr-x  2 oden  staff   64  3 10 20:54 test_dir3
      prw-r--r--  1 oden  staff    0  3 11 22:32 testfifo
      lrwxr-xr-x  1 oden  staff   13  3 11 22:03 testlink -> testdir/test3
      -rw-r--r--  1 oden  staff    0  2 19 23:11 テストファイル1
      -rw-r--r--  1 oden  staff    0  2 19 23:11 テストファイル2
    TEXT
    test_wc = Wc.new(input)
    expected = '      11      94     567'
    assert_equal expected, test_wc.output
  end
end

class WcJapaneseTest < Minitest::Test
  def setup
    input = <<~TEXT
      テスト1 テスト2
      テスト3
    TEXT
    @test_wc = Wc.new(input)
  end

  def test_count_line
    expected = 2
    assert_equal expected, @test_wc.lines
  end

  def test_count_word
    expected = 3
    assert_equal expected, @test_wc.words
  end

  def test_count_byte
    expected = 33
    assert_equal expected, @test_wc.bytes
  end
end

class WcOutputTest < Minitest::Test
  def setup
    input = <<~TEXT
      test1 test2
      test3
      test4 test5 test6
    TEXT
    @test_wc = Wc.new(input)
  end

  def test_output
    expected = '       3       6      36'
    assert_equal expected, @test_wc.output
  end

  def test_output_with_option
    expected = '       3'
    assert_equal expected, @test_wc.output(line_only: true)
  end
end

class WcOutputJapaneseTest < Minitest::Test
  def setup
    input = <<~TEXT
      テスト1 テスト2
      テスト3
      テスト4 テスト5 テスト6
    TEXT
    @test_wc = Wc.new(input)
  end

  def test_output
    expected = '       3       6      66'
    assert_equal expected, @test_wc.output
  end

  def test_output_with_option
    expected = '       3'
    assert_equal expected, @test_wc.output(line_only: true)
  end
end
