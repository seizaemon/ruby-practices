# frozen_string_literal: true

require 'minitest/autorun'
require 'pathname'
require_relative 'work_dir'
require_relative '../lib/detail_formatter'
require_relative '../lib/ls_file_stat'

class DetailFormatterTest < MiniTest::Test
  include WorkDir

  def setup
    @user_name = Etc.getpwuid(Process::UID.rid).name
  end

  # writeはファイルの詳細をテキストで出力する
  def test_write
    date_str = Time.now.strftime('%_m %_d %H:%M')
    system 'touch test_file'
    stats = [LsFileStat.new(Pathname.new('test_file'))]
    expect = "-rw-r--r--  1 #{@user_name}  staff  0 #{date_str} test_file"

    assert_equal expect, DetailFormatter.new(stats).write
  end
end
