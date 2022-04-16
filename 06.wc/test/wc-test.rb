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
