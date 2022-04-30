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
    assert_equal expected, @test_wc.line_count
  end

  def test_count_word
    expected = 3
    assert_equal expected, @test_wc.word_count
  end

  def test_count_byte
    expected = 18
    assert_equal expected, @test_wc.byte_count
  end
end

class WcComplexTest < Minitest::Test
  def test_count_case1
    input = <<~TEXT
      drwxr-xr-x  6 oden  staff  192  4 16 17:42 wctest
    TEXT
    test_wc = Wc.new(input)
    expected = { line: 1, word: 9, byte: 50 }
    assert_equal expected, test_wc.count_table
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
    expected = { line: 11, word: 94, byte: 567 }
    assert_equal expected, test_wc.count_table
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
    assert_equal expected, @test_wc.line_count
  end

  def test_count_word
    expected = 3
    assert_equal expected, @test_wc.word_count
  end

  def test_count_byte
    expected = 33
    assert_equal expected, @test_wc.byte_count
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
    expected = { line: 3, word: 6, byte: 36 }
    assert_equal expected, @test_wc.count_table
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
    input = <<~TEXT
      テスト1 テスト2
      テスト3
      テスト4 テスト5 テスト6
    TEXT
    @test_wc = Wc.new(input)
    expected = { line: 3, word: 6, byte: 66 }
    assert_equal expected, @test_wc.count_table
  end
end
