# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test/work_dir'

class LsTest < Minitest::Test
  include WorkDir

  def with_test_env(&block)
    with_work_dir do
      system 'touch test_file1 test_file2 .test_hidden'
      system 'mkdir test_dir; touch test_dir/test_file3 test_dir/test_file4'
      block.call
    end
  end

  # オプションなし
  def test_ls_normal
    with_test_env do
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb", out: w
      w.close

      expected = <<~TEXT
        test_dir   test_file1 test_file2
      TEXT
      assert_equal expected, r.gets('')
    end
  end

  # rオプション
  def test_ls_with_reverse_option
    with_test_env do
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb -r", out: w
      w.close

      # rubocop:disable Layout/TrailingWhitespace
      expected = <<~TEXT
        test_file2 test_file1 test_dir  
      TEXT
      # rubocop:enable Layout/TrailingWhitespace
      assert_equal expected, r.gets('')
    end
  end

  # aオプション
  def test_ls_with_all_option
    with_test_env do
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb -a", out: w
      w.close

      # rubocop:disable Layout/TrailingWhitespace
      expected = <<~TEXT
        .            ..           .test_hidden test_dir     test_file1   test_file2  
      TEXT
      # rubocop:enable Layout/TrailingWhitespace
      assert_equal expected, r.gets('')
    end
  end

  # lオプション
  def test_ls_with_l_option
    with_test_env do
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb -l", out: w
      date_str = Time.now.strftime('%-m %-d %H:%M')
      w.close

      # rubocop:disable Layout/TrailingWhitespace
      expected = <<~TEXT
        drwxr-xr-x  4 oden  staff  128  #{date_str} test_dir  
        -rw-r--r--  1 oden  staff    0  #{date_str} test_file1
        -rw-r--r--  1 oden  staff    0  #{date_str} test_file2
      TEXT
      # rubocop:enable Layout/TrailingWhitespace
      assert_equal expected, r.gets('')
    end
  end

  # ディレクトリ指定
  def test_ls_with_dir_argument
    with_test_env do
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb test_dir", out: w
      w.close

      expected = <<~TEXT
        test_file3 test_file4
      TEXT
      assert_equal expected, r.gets('')
    end
  end

  # TODO: 存在しないファイルを指定した場合
end
