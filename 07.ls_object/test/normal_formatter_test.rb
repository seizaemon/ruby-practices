# frozen_string_literal: true

require 'minitest/autorun'
require 'pathname'
require_relative 'work_dir'
require_relative '../lib/normal_formatter'
require_relative '../lib/ls_file_stat'

class NormalFormatterTest < Minitest::Test
  include WorkDir

  def test_write
    system 'touch test_file'
    stats = [LsFileStat.new(Pathname.new('test_file'))]
    expect = 'test_file'

    assert_equal expect, NormalFormatter.new(stats).write
  end
end
